#define _GNU_SOURCE
#include <errno.h>
#include <locale.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include <wchar.h>
#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>

#include "virtual-keyboard-unstable-v1-client-protocol.h"
#include "wlr-virtual-pointer-unstable-v1-client-protocol.h"

#define BTN_LEFT 0x110
#define BTN_RIGHT 0x111
#define BTN_MIDDLE 0x112
#define STEP_MS 15
#define MAX_MODS 32

static struct wl_display *display;
static struct wl_seat *seat;
static struct zwlr_virtual_pointer_manager_v1 *pointer_manager;
static struct zwp_virtual_keyboard_manager_v1 *keyboard_manager;
static struct zwlr_virtual_pointer_v1 *pointer;
static struct zwp_virtual_keyboard_v1 *keyboard;
static struct xkb_keymap *keymap;
static struct xkb_state *state;
static xkb_keycode_t modifier_keys[MAX_MODS];
static char error[256];

static uint32_t now(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void pause_ms(long ms) {
  wl_display_flush(display);
  struct timespec ts = {ms / 1000, (ms % 1000) * 1000000};
  while (nanosleep(&ts, &ts) == -1 && errno == EINTR)
    ;
}

static bool fail(const char *format, const char *arg) {
  snprintf(error, sizeof error, format, arg);
  return false;
}

static void global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
  if (!strcmp(interface, wl_seat_interface.name) && !seat)
    seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
  else if (!strcmp(interface, zwlr_virtual_pointer_manager_v1_interface.name))
    pointer_manager = wl_registry_bind(registry, name, &zwlr_virtual_pointer_manager_v1_interface, 1);
  else if (!strcmp(interface, zwp_virtual_keyboard_manager_v1_interface.name))
    keyboard_manager = wl_registry_bind(registry, name, &zwp_virtual_keyboard_manager_v1_interface, 1);
}

static void global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static const struct wl_registry_listener registry_listener = {global, global_remove};

static void send_modifiers(void) {
  zwp_virtual_keyboard_v1_modifiers(keyboard, xkb_state_serialize_mods(state, XKB_STATE_MODS_DEPRESSED),
                                    xkb_state_serialize_mods(state, XKB_STATE_MODS_LATCHED),
                                    xkb_state_serialize_mods(state, XKB_STATE_MODS_LOCKED),
                                    xkb_state_serialize_layout(state, XKB_STATE_LAYOUT_EFFECTIVE));
}

static void send_key(xkb_keycode_t code, bool down) {
  zwp_virtual_keyboard_v1_key(keyboard, now(), code - 8, down ? WL_KEYBOARD_KEY_STATE_PRESSED : WL_KEYBOARD_KEY_STATE_RELEASED);
  xkb_state_update_key(state, code, down ? XKB_KEY_DOWN : XKB_KEY_UP);
  send_modifiers();
  pause_ms(STEP_MS);
}

// The key that sets each modifier, found by pressing every one in a scratch state.
static void find_modifier_keys(void) {
  static const char *names[] = {"Shift_L", "Control_L", "Alt_L", "Super_L", "ISO_Level3_Shift", "ISO_Level5_Shift", "Mode_switch"};
  xkb_keycode_t min = xkb_keymap_min_keycode(keymap), max = xkb_keymap_max_keycode(keymap);
  for (size_t i = 0; i < sizeof names / sizeof *names; i++) {
    xkb_keysym_t sym = xkb_keysym_from_name(names[i], XKB_KEYSYM_NO_FLAGS);
    for (xkb_keycode_t code = min; code <= max; code++) {
      const xkb_keysym_t *syms;
      int n = xkb_keymap_key_get_syms_by_level(keymap, code, 0, 0, &syms);
      if (n != 1 || syms[0] != sym)
        continue;
      struct xkb_state *scratch = xkb_state_new(keymap);
      xkb_state_update_key(scratch, code, XKB_KEY_DOWN);
      xkb_mod_mask_t mask = xkb_state_serialize_mods(scratch, XKB_STATE_MODS_DEPRESSED);
      xkb_state_unref(scratch);
      for (xkb_mod_index_t mod = 0; mod < MAX_MODS; mod++)
        if ((mask & (1u << mod)) && !modifier_keys[mod])
          modifier_keys[mod] = code;
      break;
    }
  }
}

static bool find_key(xkb_keysym_t sym, xkb_keycode_t *code, xkb_mod_mask_t *mods) {
  xkb_keycode_t min = xkb_keymap_min_keycode(keymap), max = xkb_keymap_max_keycode(keymap);
  xkb_level_index_t best = (xkb_level_index_t)-1;
  for (xkb_keycode_t c = min; c <= max; c++) {
    xkb_level_index_t levels = xkb_keymap_num_levels_for_key(keymap, c, 0);
    for (xkb_level_index_t level = 0; level < levels && level < best; level++) {
      const xkb_keysym_t *syms;
      int n = xkb_keymap_key_get_syms_by_level(keymap, c, 0, level, &syms);
      xkb_mod_mask_t masks[4];
      if (n != 1 || syms[0] != sym || xkb_keymap_key_get_mods_for_level(keymap, c, 0, level, masks, 4) < 1)
        continue;
      best = level, *code = c, *mods = masks[0];
    }
  }
  return best != (xkb_level_index_t)-1;
}

static bool modifier_mask(const char *name, xkb_mod_mask_t *mask) {
  static const struct {
    const char *name, *mod;
  } aliases[] = {{"ctrl", XKB_MOD_NAME_CTRL}, {"control", XKB_MOD_NAME_CTRL}, {"shift", XKB_MOD_NAME_SHIFT},
                 {"alt", XKB_MOD_NAME_ALT},   {"super", XKB_MOD_NAME_LOGO},   {"logo", XKB_MOD_NAME_LOGO},
                 {"altgr", "Mod5"}};
  for (size_t i = 0; i < sizeof aliases / sizeof *aliases; i++) {
    if (strcasecmp(name, aliases[i].name))
      continue;
    xkb_mod_index_t mod = xkb_keymap_mod_get_index(keymap, aliases[i].mod);
    if (mod == XKB_MOD_INVALID)
      return fail("no modifier %s in the keymap", name);
    *mask |= 1u << mod;
    return true;
  }
  return fail("unknown modifier %s", name);
}

// Held for MS before letting go, so the client repeats it as a held key does.
static bool press_with(xkb_keycode_t code, xkb_mod_mask_t mods, long ms) {
  xkb_keycode_t held[MAX_MODS];
  int count = 0;
  for (xkb_mod_index_t mod = 0; mod < MAX_MODS; mod++) {
    if (!(mods & (1u << mod)))
      continue;
    if (!modifier_keys[mod])
      return fail("no key sets modifier %s", xkb_keymap_mod_get_name(keymap, mod));
    held[count++] = modifier_keys[mod];
  }
  for (int i = 0; i < count; i++)
    send_key(held[i], true);
  send_key(code, true);
  if (ms > 0)
    pause_ms(ms);
  send_key(code, false);
  for (int i = count - 1; i >= 0; i--)
    send_key(held[i], false);
  return true;
}

static bool key(char *combo, long ms) {
  xkb_mod_mask_t mods = 0, level_mods = 0;
  char *name = combo, *plus;
  while ((plus = strchr(name, '+')) && plus[1]) {
    *plus = '\0';
    if (!modifier_mask(name, &mods))
      return false;
    name = plus + 1;
  }
  xkb_keysym_t sym = xkb_keysym_from_name(name, XKB_KEYSYM_NO_FLAGS);
  if (sym == XKB_KEY_NoSymbol)
    sym = xkb_keysym_from_name(name, XKB_KEYSYM_CASE_INSENSITIVE);
  xkb_keycode_t code;
  if (sym == XKB_KEY_NoSymbol)
    return fail("unknown key %s", name);
  if (!find_key(sym, &code, &level_mods))
    return fail("no key types %s in the keymap", name);
  return press_with(code, mods | level_mods, ms);
}

static bool type(const char *text) {
  mbstate_t mb = {0};
  wchar_t c;
  size_t n;
  for (const char *p = text; *p; p += n) {
    n = mbrtowc(&c, p, MB_CUR_MAX, &mb);
    if (n == (size_t)-1 || n == (size_t)-2)
      return fail("not UTF-8: %s", text);
    xkb_keysym_t sym = xkb_utf32_to_keysym(c);
    xkb_keycode_t code;
    xkb_mod_mask_t mods;
    char ch[8] = {0};
    memcpy(ch, p, n < sizeof ch ? n : sizeof ch - 1);
    if (!find_key(sym, &code, &mods))
      return fail("no key types %s in the keymap", ch);
    if (!press_with(code, mods, 0))
      return false;
  }
  return true;
}

static bool button_code(const char *name, uint32_t *code) {
  if (!strcmp(name, "left"))
    *code = BTN_LEFT;
  else if (!strcmp(name, "right"))
    *code = BTN_RIGHT;
  else if (!strcmp(name, "middle"))
    *code = BTN_MIDDLE;
  else
    return fail("unknown button %s", name);
  return true;
}

static void button(uint32_t code, bool down) {
  zwlr_virtual_pointer_v1_button(pointer, now(), code, down ? WL_POINTER_BUTTON_STATE_PRESSED : WL_POINTER_BUTTON_STATE_RELEASED);
  zwlr_virtual_pointer_v1_frame(pointer);
  pause_ms(STEP_MS);
}

static void motion(double dx, double dy) {
  zwlr_virtual_pointer_v1_motion(pointer, now(), wl_fixed_from_double(dx), wl_fixed_from_double(dy));
  zwlr_virtual_pointer_v1_frame(pointer);
}

// The compositor maps it onto the box around all outputs, as it does a tablet's.
static void motion_to(double x, double y, double width, double height) {
  zwlr_virtual_pointer_v1_motion_absolute(pointer, now(), (uint32_t)x, (uint32_t)y, (uint32_t)width, (uint32_t)height);
  zwlr_virtual_pointer_v1_frame(pointer);
}

// A drag moves in steps over time, so velocity-based gestures (a flick) see a real one.
static void glide(double dx, double dy, long ms) {
  long steps = ms / 8 > 1 ? ms / 8 : 1;
  for (long i = 0; i < steps; i++) {
    motion(dx / steps, dy / steps);
    pause_ms(ms / steps);
  }
}

static void wheel(int steps, bool horizontal) {
  enum wl_pointer_axis axis = horizontal ? WL_POINTER_AXIS_HORIZONTAL_SCROLL : WL_POINTER_AXIS_VERTICAL_SCROLL;
  zwlr_virtual_pointer_v1_axis_source(pointer, WL_POINTER_AXIS_SOURCE_WHEEL);
  zwlr_virtual_pointer_v1_axis_discrete(pointer, now(), axis, wl_fixed_from_int(15 * steps), steps);
  zwlr_virtual_pointer_v1_frame(pointer);
  pause_ms(STEP_MS);
}

// Each notch its own event, all at once, as a wheel spun hard sends them.
static void spin(int steps) {
  for (int i = 0; i < abs(steps); i++) {
    zwlr_virtual_pointer_v1_axis_source(pointer, WL_POINTER_AXIS_SOURCE_WHEEL);
    zwlr_virtual_pointer_v1_axis_discrete(pointer, now(), WL_POINTER_AXIS_VERTICAL_SCROLL, wl_fixed_from_int(steps < 0 ? -15 : 15), steps < 0 ? -1 : 1);
    zwlr_virtual_pointer_v1_frame(pointer);
  }
  pause_ms(STEP_MS);
}

static bool number(const char *s, double *out) {
  char *end;
  *out = strtod(s, &end);
  return *s && !*end ? true : fail("not a number: %s", s);
}

static bool run(int argc, char **argv) {
  double x, y, ms;
  uint32_t code;
  const char *cmd = argc ? argv[0] : "";
  if (!strcmp(cmd, "move") && argc == 3)
    return number(argv[1], &x) && number(argv[2], &y) && (motion(x, y), pause_ms(STEP_MS), true);
  if (!strcmp(cmd, "to") && argc == 5) {
    double width, height;
    return number(argv[1], &x) && number(argv[2], &y) && number(argv[3], &width) && number(argv[4], &height) &&
           (motion_to(x, y, width, height), pause_ms(STEP_MS), true);
  }
  if (!strcmp(cmd, "glide") && argc == 4)
    return number(argv[1], &x) && number(argv[2], &y) && number(argv[3], &ms) && (glide(x, y, (long)ms), true);
  if (!strcmp(cmd, "press") && argc == 2)
    return button_code(argv[1], &code) && (button(code, true), true);
  if (!strcmp(cmd, "release") && argc == 2)
    return button_code(argv[1], &code) && (button(code, false), true);
  if (!strcmp(cmd, "click") && (argc == 2 || argc == 3)) {
    double times = 1;
    if (!button_code(argv[1], &code) || (argc == 3 && !number(argv[2], &times)))
      return false;
    for (int i = 0; i < (int)times; i++)
      button(code, true), button(code, false);
    return true;
  }
  if (!strcmp(cmd, "wheel") && (argc == 2 || argc == 3))
    return number(argv[1], &x) && (wheel((int)x, argc == 3 && !strcmp(argv[2], "horizontal")), true);
  if (!strcmp(cmd, "spin") && argc == 2)
    return number(argv[1], &x) && (spin((int)x), true);
  if (!strcmp(cmd, "key") && argc >= 2) {
    for (int i = 1; i < argc; i++)
      if (!key(argv[i], 0))
        return false;
    return true;
  }
  if (!strcmp(cmd, "hold") && argc == 3)
    return number(argv[2], &ms) && key(argv[1], (long)ms);
  if (!strcmp(cmd, "type") && argc == 2)
    return type(argv[1]);
  if (!strcmp(cmd, "unlock") && argc == 1) {
    xkb_state_unref(state);
    state = xkb_state_new(keymap);
    send_modifiers();
    pause_ms(STEP_MS);
    return true;
  }
  return fail("unknown command: %s", cmd);
}

static int serve(const char *path) {
  display = wl_display_connect(NULL);
  if (!display) {
    fprintf(stderr, "qs-input: cannot connect to the Wayland display\n");
    return 1;
  }
  wl_registry_add_listener(wl_display_get_registry(display), &registry_listener, NULL);
  wl_display_roundtrip(display);
  if (!seat || !pointer_manager || !keyboard_manager) {
    fprintf(stderr, "qs-input: the compositor lacks a seat or virtual pointer and keyboard\n");
    return 1;
  }
  pointer = zwlr_virtual_pointer_manager_v1_create_virtual_pointer(pointer_manager, seat);
  keyboard = zwp_virtual_keyboard_manager_v1_create_virtual_keyboard(keyboard_manager, seat);

  // NULL names read XKB_DEFAULT_LAYOUT and the rest, so the caller picks the layout.
  struct xkb_context *context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
  keymap = xkb_keymap_new_from_names(context, NULL, XKB_KEYMAP_COMPILE_NO_FLAGS);
  if (!keymap) {
    fprintf(stderr, "qs-input: cannot compile the keymap\n");
    return 1;
  }
  state = xkb_state_new(keymap);
  find_modifier_keys();
  char *text = xkb_keymap_get_as_string(keymap, XKB_KEYMAP_FORMAT_TEXT_V1);
  size_t size = strlen(text) + 1;
  int fd = memfd_create("keymap", MFD_CLOEXEC);
  if (fd < 0 || write(fd, text, size) != (ssize_t)size) {
    perror("qs-input: keymap");
    return 1;
  }
  zwp_virtual_keyboard_v1_keymap(keyboard, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1, fd, size);
  wl_display_roundtrip(display);
  close(fd);
  free(text);

  struct sockaddr_un addr = {.sun_family = AF_UNIX};
  if (strlen(path) >= sizeof addr.sun_path) {
    fprintf(stderr, "qs-input: socket path too long\n");
    return 1;
  }
  strcpy(addr.sun_path, path);
  unlink(path);
  int server = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (server < 0 || bind(server, (struct sockaddr *)&addr, sizeof addr) < 0 || listen(server, 4) < 0) {
    perror("qs-input: socket");
    return 1;
  }

  struct pollfd fds[2] = {{wl_display_get_fd(display), POLLIN, 0}, {server, POLLIN, 0}};
  for (;;) {
    wl_display_flush(display);
    if (poll(fds, 2, -1) < 0) {
      if (errno == EINTR)
        continue;
      return 1;
    }
    if (fds[0].revents && wl_display_dispatch(display) < 0)
      return 0;
    if (!(fds[1].revents & POLLIN))
      continue;
    int client = accept4(server, NULL, NULL, SOCK_CLOEXEC);
    if (client < 0)
      continue;
    char buf[4096];
    size_t len = 0;
    ssize_t n;
    while (len < sizeof buf - 1 && (n = read(client, buf + len, sizeof buf - 1 - len)) > 0)
      len += n;
    buf[len] = '\0';
    char *argv[64];
    int argc = 0;
    for (size_t i = 0; i < len && argc < 64; i += strlen(buf + i) + 1)
      argv[argc++] = buf + i;
    error[0] = '\0';
    bool ok = run(argc, argv);
    if (wl_display_roundtrip(display) < 0)
      ok = fail("%s", "lost the compositor");
    dprintf(client, ok ? "ok\n" : "error: %s\n", error);
    close(client);
  }
}

static int send_command(const char *path, int argc, char **argv) {
  struct sockaddr_un addr = {.sun_family = AF_UNIX};
  int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (strlen(path) >= sizeof addr.sun_path)
    return fprintf(stderr, "qs-input: socket path too long\n"), 1;
  strcpy(addr.sun_path, path);
  if (fd < 0 || connect(fd, (struct sockaddr *)&addr, sizeof addr) < 0)
    return perror("qs-input: connect"), 1;
  for (int i = 0; i < argc; i++)
    if (write(fd, argv[i], strlen(argv[i]) + 1) < 0)
      return perror("qs-input: write"), 1;
  shutdown(fd, SHUT_WR);
  char reply[512];
  ssize_t n = read(fd, reply, sizeof reply - 1);
  reply[n > 0 ? n : 0] = '\0';
  if (!strcmp(reply, "ok\n"))
    return 0;
  fprintf(stderr, "qs-input: %s", n > 0 ? reply : "no reply\n");
  return 1;
}

int main(int argc, char **argv) {
  setlocale(LC_CTYPE, "C.UTF-8");
  if (argc == 3 && !strcmp(argv[1], "serve"))
    return serve(argv[2]);
  if (argc >= 3)
    return send_command(argv[1], argc - 2, argv + 2);
  fprintf(stderr, "usage: qs-input serve SOCKET\n       qs-input SOCKET COMMAND [ARGS...]\n");
  return 2;
}
