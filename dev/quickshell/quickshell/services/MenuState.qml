pragma Singleton

import Quickshell

// Which menu is open, by name ("apps", later "clipboard", …). Only one menu
// is open at a time, so opening one closes any other.
Singleton {
  property string activeMenu: ""

  function open(name) {
    activeMenu = name;
  }

  function close() {
    activeMenu = "";
  }

  function toggle(name) {
    activeMenu = activeMenu === name ? "" : name;
  }
}
