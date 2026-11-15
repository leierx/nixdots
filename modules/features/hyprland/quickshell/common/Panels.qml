pragma Singleton

import Quickshell

// Which panel is open, by name ("apps", "notifications", …). Only one is open
// at a time, so opening one closes any other.
Singleton {
  property string active: ""

  function open(name) {
    active = name;
  }

  function close() {
    active = "";
  }

  function toggle(name) {
    active = active === name ? "" : name;
  }
}
