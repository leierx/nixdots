#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>
#include <wayland-client.h>

#include "security-context-v1-client-protocol.h"

static struct wp_security_context_manager_v1 *manager;

static void global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
  if (strcmp(interface, wp_security_context_manager_v1_interface.name) == 0)
    manager = wl_registry_bind(registry, name, &wp_security_context_manager_v1_interface, 1);
}

static void global_remove(void *data, struct wl_registry *registry, uint32_t name) {}

static const struct wl_registry_listener registry_listener = {global, global_remove};

static int fail(const char *message) {
  fprintf(stderr, "security-context: %s\n", message);
  return 1;
}

int main(int argc, char **argv) {
  if (argc < 4) {
    fprintf(stderr, "usage: security-context <socket> <app-id> <command>...\n");
    return 2;
  }
  const char *path = argv[1];
  const char *app_id = argv[2];

  struct sockaddr_un address = {.sun_family = AF_UNIX};
  if (strlen(path) >= sizeof address.sun_path) return fail("socket path too long");
  strcpy(address.sun_path, path);

  struct wl_display *display = wl_display_connect(NULL);
  if (!display) return fail("cannot connect to the compositor");
  struct wl_registry *registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &registry_listener, NULL);
  if (wl_display_roundtrip(display) < 0) return fail("lost the compositor");
  if (!manager) return fail("the compositor has no wp_security_context_manager_v1");

  int listen_fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
  if (listen_fd < 0 || bind(listen_fd, (struct sockaddr *)&address, sizeof address) < 0 || listen(listen_fd, 16) < 0) {
    perror("security-context: socket");
    return 1;
  }
  int close_fds[2];
  if (pipe2(close_fds, O_CLOEXEC) < 0) {
    perror("security-context: pipe");
    return 1;
  }

  struct wp_security_context_v1 *context = wp_security_context_manager_v1_create_listener(manager, listen_fd, close_fds[0]);
  wp_security_context_v1_set_sandbox_engine(context, "nixdots.nixpkgs-run");
  wp_security_context_v1_set_app_id(context, app_id);
  wp_security_context_v1_commit(context);
  wp_security_context_v1_destroy(context);
  if (wl_display_roundtrip(display) < 0) return fail("the compositor refused the security context");
  close(listen_fd);
  close(close_fds[0]);
  wl_display_disconnect(display);

  // The compositor takes connections on the socket until the write end closes, as this exits after the command.
  pid_t child = fork();
  if (child < 0) {
    perror("security-context: fork");
    return 1;
  }
  if (child == 0) {
    execvp(argv[3], argv + 3);
    perror("security-context: exec");
    _exit(127);
  }
  int status;
  while (waitpid(child, &status, 0) < 0) {
    if (errno != EINTR) return 1;
  }
  return WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
}
