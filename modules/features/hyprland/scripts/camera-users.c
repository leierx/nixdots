#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/inotify.h>
#include <unistd.h>

static const char *dir;
static size_t dir_len;
static int inotify;
static char *last;

static bool is_device(const char *name) {
  if (strncmp(name, "video", 5) || !name[5])
    return false;
  for (const char *p = name + 5; *p; p++)
    if (!isdigit((unsigned char)*p))
      return false;
  return true;
}

// Opening and closing a device node notifies a watch on the node itself; one on the directory would
// hear every open of /dev/null as well.
static void watch_device(const char *name) {
  char path[PATH_MAX];
  snprintf(path, sizeof path, "%s/%s", dir, name);
  inotify_add_watch(inotify, path, IN_OPEN | IN_CLOSE);
}

static void watch_devices(void) {
  DIR *d = opendir(dir);
  if (!d)
    return;
  for (struct dirent *e; (e = readdir(d));)
    if (is_device(e->d_name))
      watch_device(e->d_name);
  closedir(d);
}

struct buffer {
  char *data;
  size_t len, cap;
};

static void append(struct buffer *b, const char *s, size_t n) {
  if (b->len + n + 1 > b->cap) {
    b->cap = (b->len + n + 1) * 2;
    b->data = realloc(b->data, b->cap);
    if (!b->data)
      exit(1);
  }
  memcpy(b->data + b->len, s, n);
  b->len += n;
  b->data[b->len] = '\0';
}

static void append_json_string(struct buffer *b, const char *s) {
  append(b, "\"", 1);
  for (; *s; s++) {
    char esc[8];
    if (*s == '"' || *s == '\\') {
      esc[0] = '\\', esc[1] = *s;
      append(b, esc, 2);
    } else if ((unsigned char)*s < 0x20) {
      snprintf(esc, sizeof esc, "\\u%04x", *s);
      append(b, esc, 6);
    } else {
      append(b, s, 1);
    }
  }
  append(b, "\"", 1);
}

static void read_comm(const char *pid, char *comm, size_t size) {
  char path[300];
  snprintf(path, sizeof path, "/proc/%s/comm", pid);
  comm[0] = '\0';
  int fd = open(path, O_RDONLY | O_CLOEXEC);
  if (fd < 0)
    return;
  ssize_t n = read(fd, comm, size - 1);
  close(fd);
  comm[n > 0 ? n : 0] = '\0';
  comm[strcspn(comm, "\n")] = '\0';
}

// Another user's processes are out of reach, and so are their cameras' users.
static void scan(void) {
  struct buffer out = {0};
  append(&out, "[", 1);
  bool first = true;
  DIR *proc = opendir("/proc");
  if (!proc)
    exit(1);
  for (struct dirent *p; (p = readdir(proc));) {
    if (!isdigit((unsigned char)p->d_name[0]))
      continue;
    char fd_path[300];
    snprintf(fd_path, sizeof fd_path, "/proc/%s/fd", p->d_name);
    DIR *fds = opendir(fd_path);
    if (!fds)
      continue;
    char seen[PATH_MAX] = "";
    for (struct dirent *f; (f = readdir(fds));) {
      char target[PATH_MAX];
      ssize_t n = readlinkat(dirfd(fds), f->d_name, target, sizeof target - 1);
      if (n <= 0)
        continue;
      target[n] = '\0';
      if (strncmp(target, dir, dir_len) || target[dir_len] != '/' || !is_device(target + dir_len + 1))
        continue;
      // One entry per process and device, however many descriptors it holds.
      if (!strcmp(seen, target))
        continue;
      strcpy(seen, target);
      char comm[64], line[PATH_MAX + 64];
      read_comm(p->d_name, comm, sizeof comm);
      snprintf(line, sizeof line, "%s{\"pid\":%s,\"device\":\"%s\",\"name\":", first ? "" : ",", p->d_name, target + dir_len + 1);
      append(&out, line, strlen(line));
      append_json_string(&out, comm);
      append(&out, "}", 1);
      first = false;
    }
    closedir(fds);
  }
  closedir(proc);
  append(&out, "]\n", 2);
  if (!last || strcmp(last, out.data)) {
    fputs(out.data, stdout);
    fflush(stdout);
    free(last);
    last = out.data;
  } else {
    free(out.data);
  }
}

int main(int argc, char **argv) {
  static char resolved[PATH_MAX];
  if (!realpath(argc > 1 ? argv[1] : "/dev", resolved)) {
    perror("camera-users");
    return 1;
  }
  dir = resolved;
  dir_len = strlen(dir);
  inotify = inotify_init1(IN_CLOEXEC);
  if (inotify < 0 || inotify_add_watch(inotify, dir, IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM) < 0) {
    perror("camera-users");
    return 1;
  }
  watch_devices();
  scan();
  for (;;) {
    char events[64 * (sizeof(struct inotify_event) + NAME_MAX + 1)] __attribute__((aligned(__alignof__(struct inotify_event))));
    bool relevant = false;
    // A burst (a browser probing every camera) is read whole before one scan.
    for (int timeout = -1;; timeout = 50) {
      struct pollfd pfd = {.fd = inotify, .events = POLLIN};
      int ready = poll(&pfd, 1, timeout);
      if (ready < 0 && errno == EINTR)
        continue;
      if (ready <= 0)
        break;
      ssize_t n = read(inotify, events, sizeof events);
      if (n < 0 && errno == EINTR)
        continue;
      if (n <= 0) {
        perror("camera-users");
        return 1;
      }
      for (char *p = events; p < events + n;) {
        struct inotify_event *e = (struct inotify_event *)p;
        p += sizeof *e + e->len;
        if (e->mask & IN_Q_OVERFLOW) {
          watch_devices();
          relevant = true;
        } else if (e->len == 0) {
          relevant = true;
        } else if (is_device(e->name)) {
          if (e->mask & (IN_CREATE | IN_MOVED_TO))
            watch_device(e->name);
          relevant = true;
        }
      }
    }
    if (relevant)
      scan();
  }
}
