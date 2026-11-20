# AGENTS.md

Technical reference for agents working in this repo. The user-facing
quickstart and external import guide is in [README.md](./README.md).

## What this is

One flake holding all of `leier`'s NixOS and home-manager configurations,
written in the [dendritic pattern](https://github.com/mightyiam/dendritic):
there is a single top-level `lib.evalModules` evaluation, and *every* module of
every class is a value of it. There is no flake-parts dependency; the substrate
is hand-rolled in `flake.nix`, `import-tree.nix` and `modules/flake/`.

## Non-negotiables

- **A file is a feature.** One `.nix` file under `modules/features/` describes
  every class it touches (`nixos`, `homeManager`). No side files per class.
- **Share constants through the top-level configuration, never `specialArgs`.**
  Data several features read lives in a declared top-level option (`identity`,
  `palettes`, `hyprland.workspaces`) and is read as `root.config.<option>`.
  This is the dendritic substitute for importing sibling files.
- **Anything a host or an importer sets is an option of the feature's class
  module.** Top-level values are global to every host and baked into the
  exported aspects, so per-host or per-importer knobs are declared inside the
  aspect itself (home-manager `piAgent.settings`, `neovim.outOfStorePath`,
  `hyprmoncfg.profiles`) and
  set from the host's own home aspect or the importer's config.
- **Install through the module when one exists.** `programs.<x>.enable` (or
  `services.<x>`) instead of a bare package, so binds and other features can
  reference `config.programs.<x>.package`. Skip modules that would take over
  mutable app state (firefox profiles, discord/obsidian settings).
- **A feature delivers everything it relies on.** Any one aspect imported
  alone must work: tools a program calls go on its own PATH (a wrapper or
  `extraPackages`), commands in configs are store paths
  (`lib.getExe config.programs.<x>.package`), fonts a config names are
  installed by that feature, and paths come from `config` (`config.xdg.configHome`),
  not from env vars another feature exports. Only the base OS (coreutils, curl,
  tar, systemd) is assumed.
- **`imports` in a host is the whole machine.** Host builders inject only the
  hostname, platform and a `stateVersion` default; nothing else.
- **No AI credit.** Commits, PRs and files in this repo never credit Claude
  or any other agent: no `Co-Authored-By` trailer, no "Generated with" line,
  whatever a tool's default attribution says.
- **No comment is the best comment.** If one is needed, it's one line for the
  operator: why it's done this way, never what the code does. Longer only for
  a hard reason.
- Don't add a flake-parts dependency or reintroduce `specialArgs` plumbing.

## Repo map

```
flake.nix                 entry point: evalModules { class = "flake"; ... }
import-tree.nix           dir -> module that imports every .nix beneath it
flake.lock                pinned inputs
README.md                 brief user-facing doc
AGENTS.md                 this file

modules/flake/            the substrate (see below)
modules/features/         one flat file per feature (+ hyprland/, moonshine/, neovim/, pi-agent/, tmux/)
modules/profiles/         base.nix, workstation.nix
modules/theme/            palette.nix, fonts, gtk, qt, cursor
modules/hosts/            desktop/, thonkpad/
```

## The substrate

### `flake.nix`

```nix
outputs =
  inputs:
  (inputs.nixpkgs.lib.evalModules {
    class = "flake";
    specialArgs.inputs = inputs;
    modules = [ (import ./import-tree.nix ./modules) ];
  }).config.flake;
```

One evaluation, class `"flake"`, `inputs` passed as a `specialArg`. Its
`config.flake` is the flake's output attribute set. This is why every file is
a module of the same configuration and may freely read `config`, `lib` and
`inputs` at the top level.

Inputs: `nixpkgs` (26.05), `nixpkgs-unstable`, `home-manager`, `disko`,
`nix-index-database`, `hyprland` (pinned tag; its dev-only `pre-commit-hooks`
is pruned with `follows = ""`), `hyprsplit` (its `nixpkgs` follows
`hyprland/nixpkgs`, which is what it builds with anyway) and `moonshine`
(tracks upstream `main`; its `nixpkgs` follows ours, though only its sources
are used).

### `import-tree.nix`

Turns a directory into a module that `imports` every `.nix` file beneath it,
recursively. Files and directories whose name starts with `.` or `_` are
skipped — **`_`-prefixed paths are the escape hatch for non-module Nix code**
(e.g. a library file that should not be imported as a module).

### Classes and tagging — `modules/flake/outputs.nix`

`flake.modules.<class>.<aspect>` is the registry. The option type is
`lazyAttrsOf (lazyAttrsOf deferredModule)`, so:

- Multiple files assigning the *same* aspect merge (deferred modules combine).
  This is how `modules/features/hyprland/*.nix` assemble one `homeManager.hyprland`.
- `apply` wraps every module so it carries its class and origin:

```nix
{ ... }: {
  key = "flake.modules.${class}.${name}";
  _class = class;                              # nixos | homeManager
  _file = "flake.modules.${class}.${name}";
  imports = [ module ];
}
```

The `_class` tag makes loading a home-manager module into a NixOS
configuration a plain type error instead of "undeclared option" noise. The
`_file` tag gives readable error locations, and the `key` makes an aspect
imported along two paths (a profile and a host) apply once.

The registry is exported verbatim as the flake output `modules`
(hence Nix's harmless `unknown flake output 'modules'` warning), which is what
makes `inputs.nixdots.modules.homeManager.<aspect>` work from another flake.
The values a stored aspect reads from `root.config` are this flake's; an
importer changes behaviour through the aspect's own options or `lib.mkForce`.

### Top-level options

| Option | Type | Notes |
| --- | --- | --- |
| `identity` | `{ username, fullName, email }` | Primary user; read by `users`, `git`, `home-manager`, profiles. |
| `palettes` | `attrsOf (attrsOf str)` | `adwaita_darker` (libadwaita 1.9's dark style under its own names: every named colour, translucent ones as CSS `#rrggbbaa`, the accent swatches and the GNOME palette, plus ghostty's "Adwaita Dark" terminal colours; its opaque surfaces and the terminal background darkened together by 14 per channel, so libadwaita's steps between them survive and `view_bg_color` lands on `#0f0f12`, after [Darkwaita](https://github.com/varunbpatil/Darkwaita)'s darker GNOME Shell; accents, text, translucent colours and the ANSI colours unchanged; quickshell, hyprland, hyprlock, hyprtoolkit, GTK, wezterm, tmux). |
| `hyprland.workspaces` | positive int | Workspaces per monitor; read by hyprsplit's config, the binds and the quickshell bar. |
| `nixosHosts.<name>` | submodule `{ system }` | Drives `flake.nixosConfigurations`. |
| `systems` | `listOf str` | Option default `[ ]`; `per-system.nix` defines `[ "x86_64-linux" "aarch64-darwin" ]`. Drives `perSystem`. |
| `perSystem` | `deferredModule` | Evaluated once per `systems` entry. |

Flake outputs declared: `modules`, `nixosConfigurations`, `formatter`,
`checks`, `devShells`, `packages`.

### `perSystem` — `modules/flake/per-system.nix`

Each system is a nested `evalModules` of class `"perSystem"` with
`{ inputs, system, root }` as specialArgs (`root` is the top-level config).
It supplies `pkgs = import inputs.nixpkgs { inherit system; config.allowUnfree = true; }`
and options `packages`, `checks`, `devShells`, `formatter`. Results are
collected across systems into the system-keyed flake outputs. Any top-level
module may define `perSystem`; definitions merge.

### Host builders

- **`nixos-hosts.nix`** — `nixosHosts.<name>` → `lib.nixosSystem`. Injected
  defaults (all `mkDefault`, overridable): `networking.hostId` = first 8 chars
  of `sha256(hostname)`, `networking.hostName`, `nixpkgs.hostPlatform` =
  `host.system`, `system.stateVersion` = `lib.trivial.release`. Then imports
  `config.flake.modules.nixos."nixosConfigurations/<name>" or { }`.
- **`offline-installer.nix`** — for **every** entry in `nixosHosts`,
  generates `nixosConfigurations.offlineInstaller-<host>`: a minimal
  installation CD carrying that host's `toplevel` + disko
  `destroyFormatMount` script in `isoImage.storeContents`, with substituters
  and channels disabled, root autologin, keymap/locale/timezone/platform read
  from the target host, and a `offline-installer` script (`set -euo pipefail`)
  that runs disko — which lists the disks and asks for `yes` before wiping —
  then `nixos-install --no-root-passwd --no-channel-copy`.

The aspect name convention is exact and load-bearing:
`"nixosConfigurations/<hostname>"` is the host's NixOS aspect, and
`"nixosConfigurations/<hostname>/home"` its home-manager aspect, which
`home-manager.nix` imports for the user on the host whose
`networking.hostName` matches.

## Modules layer

### Features (`modules/features/`)

One flat file per feature; a directory when it has parts. Every file exports
`flake.modules.<class>.<aspect>`. Files that need shared values take
`root@{ inputs, lib, ... }:` (or plain `root:`) and read `root.config.<option>`.

| Feature | Classes | Aspect(s) | What it does |
| --- | --- | --- | --- |
| `bluetooth.nix` | homeManager | `bluetooth` | `bluetui` when the host enables `hardware.bluetooth` (via `osConfig`) |
| `boot.nix` | nixos | `boot`, `systemd-boot` | GRUB-on-EFI default (theme via `runCommand`); `systemd-boot` aspect `mkForce`s GRUB off; no host imports it |
| `desktop-apps.nix` | homeManager | `desktop-apps` | GUI apps every workstation gets (browsers, spotify, obsidian, discord, …) |
| `display-manager.nix` | nixos | `display-manager` | ly |
| `doas.nix` | nixos | `doas` | doas replaces sudo (via `doas-sudo-shim`), wheel `noPass` without `keepenv`, passing only `LANG`, `NIX_PATH` and `SUDO_UID`/`SUDO_GID`/`SUDO_USER` |
| `documentation.nix` | nixos | `documentation` | disables NixOS manpages |
| `gaming.nix` | nixos | `gaming` | Steam + proton-ge (Steam also sets 32-bit graphics) |
| `git.nix` | nixos, homeManager | `git` | git on; user identity from `identity` |
| `home-manager.nix` | nixos | `home-manager` | wires HM for `identity.username`, `useGlobalPkgs`/`useUserPackages`, `backupFileExtension = "hm-bak"`; pulls `nixosConfigurations/<hostname>/home` |
| `hyprland/` | nixos, homeManager | `hyprland` (+ top-level `hyprland.workspaces`, HM option `hyprmoncfg.profiles`) | see below |
| `incus.nix` | nixos | `incus` | incus + preseed bridge/profile/storage; no host imports it |
| `journald.nix` | nixos | `journald` | 90-day retention |
| `libvirt.nix` | nixos | `libvirt` | libvirtd + unprivileged QEMU/KVM with swtpm, virt-manager, trusted `br0` lab bridge; no host imports it |
| `locale.nix` | nixos | `locale` | `no`/`nodeadkeys`, `en_DK.UTF-8`, Europe/Oslo, timesyncd; hyprland reads the xkb values via `osConfig` |
| `moonshine/` | nixos | `moonshine` | [Moonshine](https://github.com/hgaiser/moonshine) from its own flake input, locked to upstream `main` (its NixOS module, which disables nixpkgs'; the package built against the system's nixpkgs, since its implicit Vulkan layer loads into every Vulkan app, and patched to TLS-handshake per connection with a timeout, since upstream handshakes in the accept loop and one stalled client hangs pairing and launches until a restart): a system service that gives each Moonlight stream its own headless compositor at the client's mode, leaving the desktop alone; one app, Steam `-gamepadui` in gamescope at the client's mode with the ferriscope WSI layer off (`DISABLE_FERRISCOPE_WSI`) and `--xwayland-count 2` (as on SteamOS; sharing Steam's Xwayland, a game loses X focus to the overlay, minimizes and never comes back), with the Deck UI, since Big Picture `-tenfoot` swaps the base layer across the two Xwaylands and froze the stream on the game; the user joins `input` (virtual pads without a seat) and `moonshine` (sleep-inhibit polkit rule); a desktop Steam is shut down first, since Steam is single-instance; app output goes to `journalctl --user -u moonshine-session`; the host sets `services.moonshine.openFirewall` and `uid` (the module needs it; the user's is allocated, not declared) |
| `neovim/` | nixos, homeManager | `neovim` (+ HM option `neovim.outOfStorePath`) | see below |
| `network.nix` | nixos | `network` | systemd-resolved with DNS-over-TLS to Quad9 and no plaintext fallback, NetworkManager (DHCP DNS ignored, stable MACs, wifi powersave off, no automatic wired profile), nftables, no ping, reverse-path filter `loose` (WireGuard full tunnels) |
| `nix.nix` | nixos | `nix` | GC, `auto-optimise-store`, flakes, cache, no global registry; the `nixpkgs` registry entry and `NIX_PATH` come from nixpkgs' own `nixpkgs.flake.source` |
| `nix-index.nix` | homeManager | `nix-index` | small prebuilt nix-index DB (`nix-index-database` input) + wrapped comma, no full-DB cache symlink |
| `nixpkgs.nix` | nixos | `nixpkgs`, `unstable-nixpkgs` | `allowUnfree`; overlay exposing `pkgs.unstable` |
| `packages.nix` | nixos | `packages` | jq, fzf, fastfetch, tree, kubectl |
| `pi-agent/` | homeManager | `pi-agent` (+ HM option `piAgent.settings`) | [pi](https://pi.dev) from `nixpkgs-unstable`, plus its `~/.pi/agent` settings, `APPEND_SYSTEM.md` and skills |
| `plymouth.nix` | nixos | `plymouth` | plymouth + quiet boot params |
| `podman.nix` | nixos | `podman` | podman + docker compat, DNS on `podman0` |
| `sound.nix` | nixos | `sound` | pipewire + rtkit |
| `tmux/` | homeManager | `tmux` | tmux on built-ins, themed from `palettes.adwaita_darker`: a bare `tmux` attaching to the session `main` (a package wrapper), a vim keymap on `C-b` (prefix table reset, no arrows), `choose-tree` for jumping, a copy-mode selection on the clipboard (OSC 52) as it changes, `prefix e` opening the scrollback in nvim (only with `programs.neovim`), framed pane titles, rounded popups/menus, bells from background windows marked (pi rings one) and `prefix o` to jump; resurrect + continuum loaded last by `run-shell`, since home-manager's `plugins` load before `extraConfig`; a post-save-layout hook saves each pi pane as `pi --session <its @pi_session>`, so panes sharing a directory each get their own session back |
| `users.nix` | nixos, homeManager | `users` | primary user, groups, hashed password, zsh (no global compinit; oh-my-zsh runs it) + starship, root locked |
| `wezterm.nix` | homeManager | `wezterm` | wezterm with an "Adwaita Darker" scheme from `palettes.adwaita_darker`, Hack font, notifications only while its window is unfocused |
| `xdg.nix` | homeManager | `xdg-user-dirs` | XDG user dirs (created; projects = HM default `~/Projects`) |
| `zsh.nix` | homeManager | `zsh` | oh-my-zsh, autosuggestions, syntax highlight, 100k history, `programs.fzf` keybindings (Ctrl-R/Ctrl-T/Alt-C) |

Notes on specific features:

- **`hyprland/`** is split across `default.nix` (nixos + HM base),
  `bindings.nix`, `rules.nix`, `hypridle.nix`,
  `hyprlock.nix`, `hyprmoncfg.nix`, `hyprtoolkit.nix`, `plugins.nix`, `quickshell.nix`, plus `assets/`, `scripts/`
  and `quickshell/`. It uses the
  pinned Hyprland input and its **Lua-based settings API** — binds and
  events are built with `lib.generators.mkLuaInline` and `_args` rather than
  the classic string config; `bindings.nix` has a `mkBind` helper (every bind
  carries a `desc`, shown by `hyprctl binds` for keybind menus) and generates
  the workspace, direction and XF86 media/brightness binds.
  - `plugins.nix` declares `hyprland.workspaces` and loads the `hyprsplit` Lua
    library as the local `hs`; workspace binds use `hs.dsp.focus` /
    `hs.dsp.window.move`. hyprsplit numbers monitor *k*'s workspaces
    `k*n+1 … (k+1)*n`, which the bar shows as `1 … n`.
    *k* is the monitor id, which Hyprland reuses per connector name.
  - Session daemons are home-manager user services bound to
    `hyprland-session.target` through `wayland.systemd.target`, which Hyprland
    ≥ 0.57 starts itself (home-manager's stop/start bounce is off; it only
    imports the environment), so they never start under another compositor:
    quickshell, cliphist (wiped
    as it starts, so each session begins empty),
    hyprmoncfgd, hypridle, hyprpolkitagent, hyprpaper (the wallpaper; a
    config reload restarts it) and nm-applet (whose unit hardcodes
    `graphical-session.target`, hence a `mkForce`).
  - Monitors are laid out by [hyprmoncfg](https://github.com/crmne/hyprmoncfg)
    (from `nixpkgs-unstable`, built against the pinned Hyprland so its hyprctl
    matches). Profiles are declared only: the HM option `hyprmoncfg.profiles`
    (outputs by EDID make/model/serial, workspace planning off because hyprsplit
    owns workspaces) becomes `~/.config/hyprmoncfg/profiles`, one read-only store
    directory, so the TUI cannot save a profile. SUPER+P applies one through the
    quickshell launcher's `monitors` mode, which lists the profile the daemon
    would apply on the next hotplug first, as `Recommended`.
    A catch-all `monitor` rule (preferred, auto, scale 1) covers outputs no
    profile places. `hyprland.lua` is read-only, so the module
    appends hyprmoncfg's `dofile` include itself with `lib.mkAfter`; it must stay
    the file's last line.
  - The desktop components (the bar, the launcher's SUPER+D apps, SUPER+V
    clipboard, SUPER+P monitor layouts and SUPER+Tab windows, SUPER+X power, SUPER+? keyboard
    shortcuts, the notification
    center from the bar's clock, the OSD, the privacy indicator) are a [Quickshell](https://quickshell.org)
    shell in `quickshell/`, wired by `quickshell.nix`: one `quickshell.service`
    session daemon (restarted when the shell changes, via `X-Restart-Triggers`,
    and a second after a crash, with no start limit, so a crash loop through a
    burst of hotplugs never leaves the session without one).
    Quickshell comes from `pkgs.unstable` (0.3.2), since 0.3.1 fixed crashes on
    freed objects in a `ScriptModel`, which the notification lists hold. Each
    component is its own directory owning its windows, widgets and sizes, and
    `shell.qml` only instantiates them; `common/` holds what several share:
    `Theme`, `StateFile` (a `JsonAdapter`'s file in Quickshell's state dir),
    `Shadow`, `ExpanderArrow`, `Time` (one minute clock for the bar, the
    calendar and notification ages), `Screens` (the screens someone can see:
    Quickshell's, less the headless `FALLBACK` Hyprland stands in while no
    monitor is on, and the focused one among them, the first while Hyprland
    still reports one just gone), `WorkspaceOwners` (hyprsplit's numbering,
    and what the bar calls a workspace, for the bar and the window switcher), `Command` (a process whose output
    arrives as `done`, and whose failure, a program that cannot start or
    crashes included, becomes a notification that closes
    the panel open as it started, or only a log line while `quiet`, a load nobody waits
    on), `Overlay` (the full-screen layer a panel lives in, closing it on a
    click anywhere but its `card`, and leaving `Panels` when Hyprland closes
    it with its monitor), `Card` (the surface of panels and
    popups: libadwaita's window background, outline and shadow; Escape
    closes the panel it is in), `Button` (libadwaita's button, `flat` or
    not, with an optional glyph before its text and an expander arrow after,
    and any mouse button it accepts passed to `clicked`; `CloseButton` is
    its round flat 24 px form), `Keycap` (a key as the shortcuts window and
    the power menu draw it, filled), `Glyph` (a Material Symbols path at a size),
    `WheelSteps` (wheel events as whole notches, a touchpad's small steps
    added up, for everything the wheel steps through), `Detached` (what
    must outlive the shell: apps, links, `nixpkgs-run` and the clipboard's
    `wl-copy`, which stays behind to serve a picked clip, each in a
    `systemd-run --user --scope` of its own, since the service's restart
    kills its whole cgroup, and without `QT_SCALE_FACTOR`), and `Panels`, the one
    open panel by name, with
    the IPC target `panels` (`qs ipc -c shell call panels open|close|toggle
    <name>`; `apps`, `clipboard`, `monitors`, `windows`, `nixpkgs`, `center`, `shortcuts`, `power`): opening any panel (a
    launcher mode, the notification center, a tray menu) closes the others,
    nothing opens while no monitor is on (it would land on `FALLBACK`, unseen,
    holding the keyboard), and
    `close` closes whichever is open.
    - Conventions for the QML:
      - Comments follow the repo rule strictly: none by default, no file
        headers, one line saying why, never what. What a component does is
        documented here, not in the QML.
      - Colours, fonts, radii and spacing come from `Theme`; only `Theme`
        reads `Colors`. A size that belongs to one component stays in it.
      - Shared pieces live in `common/` and are extracted at about three
        uses; a widget used in one file is an inline `component`.
      - Bindings over imperative code: handlers only react to events, and
        transient windows are created as they open (`LazyLoader`, `Variants`
        keyed by what they show) so each open starts fresh instead of
        resetting state by hand.
      - Every panel goes through `Panels`; saved state through `StateFile`.
      - Behaviour is checked against the source (Quickshell, Qt, Hyprland)
        rather than guessed, and tested before it lands, in a Hyprland
        of its own (see [Testing the Quickshell shell](#testing-the-quickshell-shell)).
      - An inline component sees the file's ids before its own properties,
        so it reads those through its own id (`list.results`, not
        `results`).
      - A `MouseArea` always sets a cursor, an arrow unless told otherwise,
        and Qt takes the topmost item with one: a `MouseArea` laid over
        others (to catch the wheel, say) or beside a parent's `HoverHandler`
        needs `cursorShape: undefined`. Qt's `qt.quick.hover.cursor` logging
        names the item that won.
      - The pointer is a hand where a click does something (opens, expands,
        picks, toggles), an arrow where it does nothing or only dismisses,
        and a closed hand while dragging (`SwipeArea`'s cards, the volume
        slider, the center's list). A disabled `MouseArea` still sets its
        cursor, so one that can be disabled names both. The tray is the
        exception: few of its icons do anything on a left click, so they keep
        the arrow.
    - Gotchas, each found the hard way:
      - A `PopupWindow` lands off by its monitor's x times
        `QT_SCALE_FACTOR` minus 1 (512 px at x 2560), right only on the monitor at 0: anything
        floating is a layer of its own on the screen (`PanelWindow`, or an
        `Overlay`), placed in that screen's coordinates.
      - Qt's JavaScript lacks some of ES2019 and later, `Array.flatMap` among
        them: `map` and spread instead.
      - PipeWire's link state reads `Unlinked` and a node's `properties`
        `{}` until a `PwObjectTracker` holds them.
      - Quickshell types only the plain media classes: `Audio/Source/Virtual`,
        `Stream/Input/Video` and the like are untyped (0), and an untyped
        node has no `audio`, so no volume or mute; tell them by
        `properties["media.class"]`.
      - `font: Theme.x` and `font.strikeout` on one item is "Property has
        already been assigned a value": a whole `Qt.font({ ... })` instead.
      - An IPC function named `show` is taken by `qs ipc`'s own subcommand.
      - `systemctl is-active` exits non-zero for every state but active, so
        it is a `Process` reading stdout, not a `Command`.
      - A Hyprland bind dispatching `hl.dsp.global` runs again on release,
        anything else in it too: a global gets a bind of its own.
      - Hyprland reports no lock-key changes, and its `input.keyboard.key`
        Lua event comes before the keyboard's new state.
      - Hyprland's `screencast` event comes for any capture (grim, the
        shell's own window previews, xdph's frames) and goes 500 ms after the
        last frame, so it flaps with a still screen: it cannot tell a screen
        is shared.
      - A script killed by the shell leaves its pipeline's other processes
        running until their next write: a long-running reader is a process
        substitution the script kills on exit.
      - qmllint is wrong about `Edges.Bottom` assigned to an `Edges` flags
        property and about `PanelWindow`'s `margins` group; the first takes a
        `// qmllint disable incompatible-type` pair, the second sizing the
        window instead.
      - An item sized from its `Row`'s implicit width, while a child's width
        is clamped by the item's own, settles at zero without a warning: the
        text simply vanishes. Size from the children's implicit widths
        (`Button.contentWidth`).
      - `visible` reads false under a hidden ancestor, so a size worked out
        from a child's `visible` is wrong while the whole is hidden; test what
        makes it visible (`text !== ""`) instead.
      - `Theme`'s fonts are point sizes, so `font.pixelSize` reads -1; a
        line's height is a `FontMetrics`' `height`.
      - qmllint types `QsWindow.window` as a plain `QObject` ("Member
        `height` not found"); Qt's attached `Window.height` is typed.
      - A `Singleton` is created on first use, so an `IpcHandler` in one
        nothing has read yet does not exist, and `qs ipc` answers a missing
        target with "Target not found." and exit status 0.
      - Holding a value at the moment a state flips depends on which binding
        updates first; derive it from what stays put instead (what a popup's
        text loses on collapsing, from its line counts).
      - Switching `Layout.alignment` snaps; to ease something across a
        layout, animate a `Layout.topMargin` bound to a property with a
        `Behavior` (the center's text when a card expands).
      - A `Behavior` whose duration or easing follows the flag that drives its
        value may start before they update, so it runs with the old ones (the
        OSD faded out in its fade-in's 80 ms): two
        `NumberAnimation`s started from the flag's change handler instead.
    - `Theme` is libadwaita's dark style 1:1, on the darker palette: its named colours
      (`palettes.adwaita_darker`, `view_bg_color` surfaces), hover/selection/
      border as the foreground at libadwaita's alphas over any surface, its
      type scale as `font` values (`Theme.body`, `heading`, `caption`,
      `title4`, …; Adwaita Sans at GTK's 11pt) and its radii (button 9, card
      12, window 15), plus the shadows', the power menu's and the idle fade's black. Every
      colour the shell draws is one of these. A button is the foreground at
      10 % at rest (none when flat), 15 % under the pointer and 25 % pressed or
      open, and every hover or press fades over `Theme.fade` (150 ms). Panel widths follow GNOME Shell's, in em of the body
      font (`Theme.em`): 30em popups (GNOME's are 34em), its calendar
      days. `shell.qml` sets `QT_SCALE_FACTOR=1.2` (an `Env`
      pragma), Qt's own high-DPI scaling, so it all draws 1.2× and sharp;
      apps and links the shell opens get the variable removed.
    - Design standards, so a new widget looks and behaves like its siblings:
      - Reach for the shared piece before drawing one. A bar item is a
        `BarButton` (a text pill, or a circle round an icon), never its own
        `Rectangle` and `MouseArea` (the tray, a module rather than buttons,
        aside); any other button a `Button` (`flat` on
        a surface, `glyph` for its icon, `checked` while what it opens is
        open); the round 24 px `CloseButton`; what expands a bare
        `ExpanderArrow`, a sign rather than a button, since a click on the card
        toggles it; a key a
        `Keycap`; a Material Symbols icon a `Glyph` and an app's a
        Quickshell `IconImage`; a notification's `NotificationIcon`; anything
        floating a `Card` in an `Overlay`.
      - Shapes: a pill or a circle is `radius: height / 2`, never half its
        size typed out. Rounded rectangles take `Theme`'s radius for their
        role: `smallRadius` (6) for list and menu rows, keycaps and
        workspaces; `buttonRadius` (9) for buttons, inset cards and
        pictures; `cardRadius` (12) for popovers hung off a bar item and
        cards on a panel; `windowRadius` (15, `Card`'s default) for panels,
        windows and notification popups.
      - Sizes: bar items are 26 px with 18 px glyphs and 10 pt lettering
        (`BarButton`'s); buttons 34 px (`Button`'s); rows in a popover list
        32 px with `Theme.border` rules (the tray menu's); count badges 8 to
        10 pt bold on a pill. Panels and popovers pad `Theme.padding` (12),
        menus 6, and keep `Theme.gap` (10) from the screen's edges; a popover under the bar
        sits the bar window's own height (`Window.height`) plus `Theme.gap`
        down, never a typed bar height.
      - States: through `Button` where it can; otherwise the same steps
        (`Theme.button` at rest, `buttonHover` under the pointer,
        `buttonChecked` pressed or open). Rows hover `Theme.hover` and select
        `Theme.selected`; cards on a panel are `Theme.card` and `cardHover`;
        a critical one is `Theme.criticalCard` in a list and outlined in
        `Theme.destructive` when it floats. Colour changes fade over
        `Theme.fade`.
      - Motion: moves, resizes and slides take 200 ms `Easing.OutCubic`
        (popups slide out `InCubic`); the center opens over 180 ms `OutCubic`
        and closes over 120 ms `InCubic`. Keyboard selection never animates
        (the launcher), so the list keeps up with the keys.
      - Input: the pointer follows the rule under the conventions above;
        anything the wheel steps through counts notches with `WheelSteps`,
        and only a list that scrolls smoothly (the center's) glides instead.
      - Text: `Theme`'s fonts; a size of its own is a whole `Qt.font` from
        `Theme.body.family`. Long text elides at a line limit rather than
        being clipped.
      - A new visual piece is drafted first: a few options shot in the test
        session for the user to pick from, then built, linted (`qst lint`),
        given probe fields and a scenario where it has behaviour, and
        described here.
    - The shell is written like any Hyprland rice, so it works on other
      setups: the QML runs its tools by name from PATH (`cliphist`, `wl-copy`,
      `pw-play`, `notify-send`, `xdg-open`, `systemd-run`, `hyprmoncfg`,
      `wezterm`, `curl`, `nixpkgs-index`, `nixpkgs-run`, `hyprctl`, `systemctl`,
      `camera-users`, `backlight-watch`) rather than store paths, an exception to the rule above;
      `quickshell.nix` installs the ones no other feature does. The only Nix
      in the QML is `palettes.adwaita_darker` as the `Colors` singleton (translucent
      colours turned into Qt's `#aarrggbb`) and `hyprland.workspaces` as
      `Hyprsplit.workspaces`, in a `qs.nix`
      module added to the store copy, so it only runs from the built copy
      (`programs.quickshell.configs.shell`), not the checkout. A new component
      is a directory with a `Scope`, a line in `shell.qml`, an `IpcHandler`
      if scripts drive more than its panel, and for a keybind a `GlobalShortcut` (Quickshell.Hyprland)
      bound in `quickshell.nix` with `hl.dsp.global("quickshell:<name>")`,
      which reaches the running shell without starting a `qs ipc` process.
    - `launcher/` is one launcher with a mode per feature, each opened by its
      own global shortcut (`quickshell:launcher-<name>`, or `qs ipc -c shell
      call panels toggle <name>`): SUPER+D `apps`, SUPER+V `clipboard`,
      SUPER+P `monitors`, SUPER+Tab `windows`, SUPER+N `nixpkgs`. Nothing in one mode points to
      the others; a second shortcut while open starts that mode afresh.
      Keyboard driven: Up/Down, Ctrl+P/Ctrl+N, Tab and Shift+Tab move a
      row and go round at the ends (the wheel stops there). Ctrl+U/Ctrl+D
      jump half a page and Page Up/Page Down a page, stopping at the ends. Enter picks,
      Shift+Delete removes, Escape closes.
      A mode is a `LauncherMode` in `<Name>Mode.qml`, listed in
      `Launcher.qml`, which makes its shortcut. It sets a `name`, a `title`,
      a `glyph` (a Material Symbols Rounded path, Apache-2.0, pasted in and
      named in a comment; drawn bare in white, so a mode never looks like
      an app), or an `image` in its own colours instead, an optional `accent`
      (two colours drawn round the card as Hyprland draws an active border:
      30°, half each) and a `placeholder`; its `rows` and the `fields` searched in
      them; an `activated` handler, a `removed` one where it is `removable`;
      `opened` to load what it lists; `wide` for a wider card; `find`, its
      own search for a list too long for the shared one;
      `split`,
      the list's share beside a preview (0.6); and
      optionally a `preview`, a component (inline in the mode's file) shown
      beside the matches for the `selected` row. Rows carry a unique `key`,
      by which a `ScriptModel` keeps their delegates as a search changes, a
      `title`, and optionally a dim `subtitle`, an `icon`, a `glyph` or a
      monitor `layout` to lead it, a `thumbnail` (with its `size`) at its
      end, and a `boost` that orders equal matches. `LauncherWindow` is the
      one design for all of them: a card with the mode's glyph and the field,
      the matches below it with ↵ on the selected row (not on a picture's),
      what the query matched in bold, as rofi does, nothing below it while
      nothing matches, and with a preview the card wider, split by the
      mode's `split` under a line across; without a preview the rows start
      right under the field. One hover for the list, not each row's, holds
      across the gaps between rows and a pointer leaving for a moment.
      Widths are in em and the card and its rows shrink to fit the screen,
      so it holds at any scale. It is always centred on the screen and holds
      still while typing: every mode opens at full height, listing all its
      rows before anything is typed, without an animation.
      Search matches every typed word as a substring, or in a
      loose field (an app's name) as its letters in order (`ffx` finds
      Firefox) for a lower score. Hyprland's `quickshell:launcher` layer
      rule dims behind it.
      - `apps`: apps used most come first among equal
        matches: `AppUsage.qml` keeps one frecency number per app in the
        state dir, log2 of the sum of 2^(launch time in weeks), so a launch
        counts half a week later and nothing ever needs decaying. Apps start
        in their own `systemd-run --user --scope`, so restarting the service
        leaves them running. The mode loads the desktop entries, icon theme,
        every app's icon and app use at startup so the first open is as
        quick as the rest (an icon Papirus lacks costs thousands of failed
        stats).
      - `clipboard`, wide and without a preview: cliphist's history, newest
        first, shown as soon as `cliphist list` returns. Text says its
        length under it ("84 characters, 4 lines"),
        counted once per clip into Quickshell's cache since it needs the clip
        decoded. Pictures say their size and format,
        and are decoded into the cache (pruned to what cliphist still lists)
        for a thumbnail at the row's end, shrunk to fit and never enlarged;
        one past 64 MiB or 50 megapixels gets none. One script fills the
        cache after the rows show, prunes it and reports every thumbnail
        and count, with a fork per new clip and a few in all; both are kept
        between opens, so only a new clip's arrive late. It also runs at the
        shell's start, ordered after cliphist's wipe, so pictures of a past
        session's clips leave the disk with them.
      - `monitors`, split half and half: `hyprmoncfg status --json`'s
        profiles, the recommended one first, loaded at the shell's start and again on
        every open, and replaced only when the output differs, so it opens
        whole and a refresh changes nothing that is the same; one that fails,
        mid-hotplug say, only logs while there is a status to show. It loads
        again a second after the last of a burst of hotplugs, once hyprmoncfgd
        has applied its pick, so the next open already shows it.
        Each is drawn by `LayoutDiagram` from its file in
        `~/.config/hyprmoncfg/profiles`, so any machine's layouts draw
        themselves: outputs at their logical size (scale and rotation
        applied), numbered left to right, those a profile turns off outlined
        where the profile turning on the most outputs has them (above, below or
        beside, shifted so an output on in both lines up, or in a row to the
        right when that fails), each labelled with its connector (`DP-1`) while
        plugged in, and those saved without a size left out. Past eight outputs
        (four in a row's icon), or once one would be under 4 px, the drawing
        becomes a count. The preview draws it as
        large as fits
        and lists the outputs, six lines at most, each with its connector,
        model, size in inches (Hyprland's mm, while plugged in), mode, scale, and position (`at 2560x0`) for one not plugged in; one turned off has an
        outlined badge.
      - `nixpkgs`: every package of nixos-unstable not marked broken, with
        the NixOS logo and its two blues as the accent. `nixpkgs-index`
        (`scripts/`) keeps the list in Quickshell's cache as TSV, revision
        first: it follows the channel's redirect to its release and only
        when that moved fetches `packages.json.br` (curl decodes the
        `Content-Encoding: br`) and has jq cut it down, a few seconds and
        about 3 GB at idle priority. It runs at the shell's start and on
        every open, and a list it brings while open is read on the close,
        so each open searches the list it opened with; a failed fetch only
        notifies on an open with no list. The mode keeps
        columns rather than an object per package and scores them in one
        loop of its own (a call into `search.js` per package costs ten times
        the matching), keeps every query of an open with its matches, so
        backspace is instant and a query extending one searches only its
        matches, keeps only the best 50, and before anything is typed lists
        only what was run before (`AppUsage`, under `nixpkgs:`, its boosts
        worked out once an open). A mode with its own `find` searches a frame
        after the key, so the letter shows before the matches and a burst of
        keys is one search; Enter and the keys that move the selection run
        the search first. Enter runs `nixpkgs-run <rev> <attr>
        <program>` in its own scope: `nix build` of
        `github:NixOS/nixpkgs/<rev>#<attr>` (unfree allowed), then the
        program `nix run` would pick, as a transient `systemd-run --user`
        service sandboxed by systemd alone: `ProtectSystem=strict`,
        `PrivateTmp`, a writable tmpfs over `$HOME` and `$XDG_RUNTIME_DIR`
        (`ProtectHome=tmpfs` is read-only, which apps fail on), only the
        PipeWire and X11 sockets and GTK/fontconfig/cursor settings
        bound back in, and the nix daemon socket and both D-Bus buses out of
        reach, since through any of them it could have something outside
        write for it. Wayland comes through a socket of its own made by
        `security-context` (`scripts/security-context.c`), a
        `wp_security_context_v1` listener, for which Hyprland hides every
        protocol off its whitelist (virtual keyboards and pointers,
        screencopy, toplevel export, layer shell), since with the real socket
        a program could press SUPER+Return and type into the terminal it
        opens. Hyprland takes connections on it only while `security-context`
        runs, so it waits on the program (`systemd-run --wait`, or the
        terminal). X11 apps still share Xwayland with the desktop's own. The
        user manager implies `PrivateUsers`, so it needs no privileges;
        scopes take no sandboxing, hence a service. A package
        with a desktop entry for the program (not `Terminal=true`) runs
        on its own, notifying if it stops with an error, anything else in
        wezterm under `--pty --wait`, held open on a failure or a run under
        5 s. While it builds, a low-urgency card that never expires shows
        the progress from nix's `--log-format internal-json`, which
        `scripts/nixpkgs-progress.jq` reduces: "Fetching" while evaluating,
        then the download's MiB against the total nix expects, and
        "Building" with builds done of expected while one runs, updated by id
        at most twice a second. A `notify-send --wait` holds the card, so one
        dismissed mid-build stays gone; it closes as the program starts. A
        failed build replaces it with a critical one and nix's last lines;
        what it builds stays in the store until GC.
      - `windows`: every window from wlr-foreign-toplevel
        (`ToplevelManager`), so it works on any compositor, the focused one
        last. On Hyprland the rest come in focus order (a `refreshToplevels`
        as it opens), each with its monitor and workspace as the bar names
        it (`DP2-1` for one left by an unplugged DP-2), and Enter dispatches `hl.dsp.focus({ window = "address:0x…" })`;
        elsewhere it calls `Toplevel.activate()`. The preview is the window
        live (`ScreencopyView`, mipmapped from up to twice its shown size so
        it shrinks smoothly) in a frame shaped by the size Hyprland reports
        before the first frame arrives, outlined, since a dark window on the dark
        card has no edge of its own. A window on a hidden workspace shows its
        last frame. Quickshell can only capture it through Hyprland's toplevel
        export; elsewhere it shows the app's icon.
    - `shortcuts/` is the keyboard shortcuts window (SUPER+?, bound as
      SUPER+SHIFT+plus since Hyprland matches binds on the unshifted key; as GTK apps
      use Ctrl+?), GTK's shortcuts window in groups balanced over up to three
      columns, each row a description and its keys as keycaps. It takes the
      column count that needs the least shrinking to fit the screen, and
      shrinks whole only when none fits. It reads
      `hyprctl binds -j` on every open, so it lists whatever binds carry a
      description: numbered ones ("Focus workspace 1" … "6") fold into one
      row, as do directions ("Focus left" … "right" become "Focus", keys
      `H J K L` in Vim's order), a submap's binds (none now) form a group under the bind whose
      description its name begins ("system_control", "System controls") and
      read "Super X then L", media keys are left out, and the rest are grouped
      by their description into General, Windows, Workspaces and Mouse. Its
      `quickshell:shortcuts` layer rule dims behind it.
    - `power/` is the power menu (SUPER+X, or the bar's NixOS logo), full
      screen over a backdrop of its own (black at 88%, so no layer rule):
      the clock and date, five solid tiles (Lock, Suspend, Log Out, Restart,
      Power Off) with their letters as keycaps, then smaller Reload Hyprland
      and, on UEFI machines (`/sys/firmware/efi`), Restart to Firmware above
      the host and uptime, which only a click reaches. A tile's letter or
      Enter picks it; Log Out, Restart, Power Off and Firmware take a second
      press within 5 s, turning red and saying so under the tiles, and moving
      the selection drops it. Arrows and Tab move along the tiles, Escape or
      a click off the buttons closes. Every action is a command
      (`loginctl lock-session`, `systemctl suspend|reboot|poweroff|reboot
      --firmware-setup`, `hyprctl dispatch 'hl.dsp.exit()'`, `hyprctl reload
      full-reset`), so `qst actions` shows what it would have done. Delegates
      get copies of the action objects, so actions are told apart by title.
    - `bar/` is the bar along the top of every monitor (`Bar.qml`, one
      `BarWindow` per screen but `FALLBACK`), one black strip across it
      (GNOME Shell's panel black). Left: the NixOS logo (`nixos.svg`, opening
      the power menu, a third of a turn in 0.6 s each time the pointer
      arrives, after which its two blues are where they were; a turn under
      way finishes rather than starting over) and the workspaces. Centre: the
      clock (a flat round button with a pointing hand, as GNOME's panel draws
      its date: shaded on hover and while the center it opens is open).
      Right: the privacy indicator, the volume, the battery, Caffeine's cup,
      the bell and, always last, the tray. Every one of them but the
      workspaces, the battery and the tray is a `BarButton`, the bar's one shape: a
      flat 26 px pill, or a circle round an icon alone, its glyphs and icons
      18 px and its lettering 10 pt. Quickshell keeps Hyprland's state by
      events but only refreshes monitors as one comes or goes and ignores
      renames, so `Bar.qml` refreshes monitors and workspaces on those, and
      once more 300 ms after the last, since Quickshell drops a refresh while
      one is under way and a hotplug comes as a burst. It also drops for good
      a window opened on a workspace it has not loaded yet, as at login, so
      the bar reloads the windows on every `openwindow`, and 300 ms after the
      last; a workspace is occupied while its `toplevels` hold one.
      - Workspaces: the monitor's own `1 … n` (monitor id × n + 1 onwards, as
        hyprsplit numbers them) as bare numbers, white while shown, near white with
        windows (told from the shown one by its squircle), faint without, red when urgent, in a 26 px squircle shown only while it is
        shown (a button's shade, and bolder lettering) or under the pointer; a step darker on a
        monitor without focus, read from `Hyprland.focusedMonitor`
        since Quickshell binds `HyprlandMonitor.focused` only on monitors
        added after it started. Any other workspace on it follows as an
        outlined pill named after the monitor that owns it (`DP2-1`), white
        while shown, and named ones by name; specials are left out.
        `WorkspaceOwners` remembers the connector last seen with each monitor
        id in the state dir, so a workspace left behind by an unplugged
        monitor still carries its name (the bare id if never seen; never
        `FALLBACK`, whose id is a real monitor's). Each one's target is the
        bar's whole height and the gaps beside it; pressing one dips it once (an animation played through, not held while pressed) and focuses it by
        id wherever it is, and the wheel over them steps one a notch in the
        order the bar shows them, stopping at the ends (`WheelSteps`).
      - The tray is a module rather than buttons: its items' icons, hiding
        passive ones, on one pill in the button shade (`Theme.button`), each
        with an arrow pointer and no hover, since most do nothing on a left
        click;
        left click activates (or opens the menu of a menu-only item), middle is the secondary action, right opens
        the menu: `TrayMenu`, libadwaita's popover menu drawn from
        `QsMenuOpener` with its corner at the pointer (leftwards where it would
        run off the screen), on an overlay (a `Panels` panel per screen) whose
        input region is only its cards (`Region.regions`), stray separators
        dropped. Check and radio items get libadwaita's check buttons, and only
        rows with a check button or an icon make room for one, so the others start at the edge.
        Submenus cascade as GTK's do: a card each, beside the row that
        opens it (held highlighted), opened by a click or 150 ms of hover, so
        passing over rows opens nothing, and closed as soon as the pointer is on
        another row of its parent; each goes the way the last
        one went until another its width would not fit. Arrows point right on
        the right whichever way it opens, as GTK's do. Open submenus are kept by
        label, so one stays open when its app rebuilds the menu with every entry
        new, as nm-applet does whenever the networks change. Like a GTK menu it takes no keyboard and no grab,
        so the app in front keeps both and a click elsewhere goes through; it
        closes 100 ms after the pointer is on neither it nor its icon (Hyprland
        reports no hover on a new menu until the pointer moves).
        Another icon switches menus, the same icon closes it, its monitor going closes it too,
        and a click on the bar besides its buttons closes any open panel.
      - The volume (`Volume`) is PipeWire's default output: an icon for its
        level (Material Symbols' volume_up, volume_down, volume_mute,
        volume_off) and its percentage, struck through while muted. The wheel
        on it steps 5 % a notch (`WheelSteps`), onto the 5 % marks and up to
        100 %, or to wherever past it another app set it, so turning it up
        never turns it down; the slider reads full past 100 %. A right click
        mutes, and a click opens
        `VolumePopup` under it (a `Panels` panel per screen, `volume:DP-1`),
        libadwaita's popover: a mute button, a slider (dragged, clicked or
        wheeled), and the outputs, the one in use ticked, a click making
        another `Pipewire.preferredDefaultAudioSink`; its rows are the tray
        menu's (32 px, `Theme.smallRadius`, `Theme.border` rules). A node's volume only
        arrives while a `PwObjectTracker` holds it. `qs ipc -c shell call bar
        fakeVolume 64 false` stands in for a sound server with three outputs,
        `realVolume` drops it.
      - The battery (`Power`) is UPower's display device, shown only when
        UPower is running and it is a laptop battery, so only thonkpad
        enables UPower: a thick meter with its nub, the percentage on it,
        dark over the fill and light past it (drawn twice, the dark copy
        clipped to the fill), green, yellow from 25 %, red from 10 %, with a
        bolt while charging. `qs ipc -c shell call bar fakeBattery 15 false`
        shows a made-up one anywhere, `realBattery` drops it.
      - The bell shows while there are notifications not yet looked at in the
        center (`Notifs.unchecked`: those that arrived, or came again, while it
        was closed), in `Theme.bell` (the palette's `yellow_2`) with their
        count in red, and for as long as Do Not Disturb is on, struck through
        (Material Symbols' notifications_off) in `Theme.dnd` (`purple_1`),
        without the count. Purple, a click turns Do Not Disturb off; yellow,
        it opens the center, which checks them all, so the bell goes at once. A reload of the shell hands every
        notification over unchecked.
      - Caffeine's cup (`Cup`, Material Symbols' coffee, in `Theme.coffee`, the palette's
        `brown_2`) shows while it is on, so it is not left on by mistake; a click
        turns it off.
      - The privacy indicator (`PrivacyIndicator`) shows only while something
        records: a button's grey pill holding a red recording light, breathing slowly (4 s),
        and the bar's white symbols for each kind recording (mic, videocam,
        screen_share). Hovering it for 250 ms opens `PrivacyTooltip`, a card
        under it (a click-through layer of its own on the bar's screen, since a
        `PopupWindow` there lands off by the monitor's x times
        `QT_SCALE_FACTOR` - 1, 512 px on a monitor at x 2560) listing each kind with the apps, named and
        iconed from their desktop entries (`DesktopEntries.heuristicLookup`, so
        a `firefox` process reads as Firefox). `Privacy` is the backend:
        - Microphone: a PipeWire link into a capture stream
          (`Stream/Input/Audio`) in state Active, from a source
          (`Audio/Source` or `Audio/Duplex`, or by its `media.class` a virtual
          one, which Quickshell leaves untyped), named by the stream's
          `application.name`. A sink's monitor is no microphone; peak meters
          (`stream.monitor`, which pipewire-pulse sets for peak detection, and
          pavucontrol's, GNOME's and KMix's app ids) and passive filters
          (`node.passive`) are left out. Link state only arrives for link
          groups a `PwObjectTracker` holds, so it tracks those into capture
          streams and out of video sources.
        - Screen: a video source a program makes (xdph's `xdph-streaming-*`,
          or any `Video/Source` without a `device.api`), shown for as long as
          it exists, named by the streams linked to it. Programs that capture
          the screen without the portal (wf-recorder) are not seen.
        - Camera: a device video source (`device.api`) with an Active link,
          named by its viewer, and any process holding `/dev/video*` open for
          half a second (`camera-users`, `scripts/camera-users.c`: inotify on
          each device node for opens and closes and on `/dev` for devices
          coming and going, then a scan of `/proc/*/fd`, one JSON line per
          change), so V4L2 apps (Chrome, Zoom) count and a browser probing
          devices does not. PipeWire's and WirePlumber's own holds are left
          out: their clients are named through the links. The watcher is
          restarted after it stops, backing off to 5 minutes.
    - `weather/` is the `Weather` singleton and `Forecast`, its card under
      the center's calendar: MET Norway's forecast (yr.no's) for the
      timezone's city (`/etc/localtime`'s zone, placed by the `zone.tab`
      beside it, so Europe/Oslo is Oslo, and no lookup of the public address),
      fetched with `curl` from the shell's start and every half hour after
      (five minutes after a failure, and at once when the clock shows a
      suspend skipped one),
      coordinates at two decimals for
      MET's cache. `hours` runs hourly from the hour under way (`now`) by the
      clock, so an old forecast runs out rather than going stale: its
      temperature, MET's symbol code and icon. The card, laid out like
      Windows' weather widget, has the icon, the place over the temperature
      in °C, the condition and the next 24 hours' high / low on the right
      (the rest of today is an hour or two late in the evening), and the
      next six hours below. The icons are MET's own
      ([metno/weathericons](https://github.com/metno/weathericons), MIT),
      which `quickshell.nix` fetches into `weather/icons/` with their
      `legend.csv`, which names the symbols ("Partly cloudy").
    - `notifications/` is the notification daemon (no mako) and its popups:
      `Notifs.qml` owns `org.freedesktop.Notifications` and keeps every
      notification as a `NotifEntry` until it is dismissed; the entry holds a
      `RetainableLock` and outlives the close by a second, so views slide a
      closed notification away whole. Popups stack top right on the monitor
      focused when each arrived (one whose monitor goes moves to the focused one
      for good, and while none is on it waits with its timeout held), below the bar, sliding in and out (the
      window stays mapped with an empty input region, so the last one does
      too); the app's timeout or 8 s, critical never, hovering pauses it, and those above it on its screen too, since their
      going would move it from under the pointer; each carries on from there
      after.
      A bar along each card's bottom edge (the accent blue) drains over its
      timeout, so it stands out over a terminal as dark as it. The bar is
      the entry's own countdown (`NotifEntry.remaining`): paused while held (hover,
      no room, no monitor) and carrying on after, full again each time it pops up or an update
      restarts it; one that never expires (critical, or
      timeout 0) has none, and a critical one has a red outline. It names
      neither the app
      nor its age: the icon and text say who, and a popup is always now. The
      image is at the top, by the title, and text shorter than it is centred
      on it. Expanding and collapsing ease the card's height (200 ms
      `OutCubic`), its content clipped; collapsing keeps the whole text until
      the card has eased down to the height it will have (what the text loses
      worked out from its line counts), then elides it; the arrow by the title is only a sign of it. The image is the picture, the app's icon a badge on
      it unless the picture is that icon, or without one the app's icon (its
      initial when it has none) on a plate (`NotificationIcon`, shared with
      the center). A click on one with more to show (a cut-off title or body)
      expands it and a second click collapses it, as in the center, so a
      long one's click never runs its action; a click otherwise runs the
      default action, or the only action when there is one and no default,
      or puts the popup away when there is neither; an action or a link puts it
      away too (a resident notification stays open, as GNOME's banners do);
      right click, a swipe or a fast flick towards the edge slides it away and
      dismisses it; more than three actions fold into a "More" dropdown.
      Popups are never grouped and have no close cross; in the center only a
      card a click expands has one.
      A transient notification leaves the history with its popup, and one that
      cannot pop up (the center open, Do Not Disturb, fullscreen) is dropped as
      expired. One with the same `x-canonical-private-synchronous` or
      `x-dunst-stack-tag` tag as an earlier one (volume, brightness) updates it
      in place, as an update by id does, rather than sliding a new card in;
      either moves it first, pops it up again on the focused monitor, and
      plays its sound only when it pops up anew. Past five popups the newest
      always shows, the oldest go first, and critical or never-expiring ones
      last; one past the screen's edge waits out of sight, its timeout held,
      until there is room, and the window's input region is the cards alone,
      so the gaps between them click through. Like GNOME, each app keeps its
      newest three notifications (one still popped up stays until its popup
      goes), and a reload of the shell lists the notifications it hands over
      again without popping them up.
      Like GNOME, while the focused window is fullscreen (Wayland's
      foreign-toplevel state, so maximised windows don't count) only critical
      notifications pop up, on the overlay layer above it, and going
      fullscreen puts the others away. Ages read "now", "5m", the time today,
      "Yesterday", the weekday within a week, then the date. Bodies drop the
      link to the site Chromium puts first, and stray blank lines, and keep
      only the markup the spec allows without body-images (`b`, `i`, `u`,
      `br` and `a`, links only to http, https and mailto), since StyledText
      would load images and obey `font` and the rest; that filter is
      `markup.js`, tested by `checks.<system>.notification-markup`.
      `NotificationActions`, `NotificationImage`, `NotificationText` (a body
      whose links open, with a pointing hand over them) and `SwipeArea`
      (which moves its card itself, and slides it away carrying on from the
      drag) are shared with the center, and `NotificationAge` is the
      center's. Do not disturb is saved in
      Quickshell's state dir and lets only critical notifications pop up.
      Sounds are elementary OS's (Unlicense) in `sounds/`, played with
      `pw-play` (Quickshell has no QtMultimedia) when a popup shows; low
      urgency is silent whatever it asks, and `suppress-sound`, `sound-file`
      and `sound-name` (looked up in the freedesktop sound theme) are
      honoured, so the server advertises `sound`. Scripts use
      `qs ipc -c shell call notifications
      <toggleDnd|setDnd|dnd|count|clear|hidePopups>`.
      The history outlives a restart of the service (`History`): Quickshell's
      state dir holds `notification-history.json`, written atomically half a
      second after a change, at most 100 notifications and none past 7 days
      (`history.js`, tested by `checks.<system>.notification-history`),
      transient ones never. Read back as the shell starts, each is a
      `PastNotification` with what the views show and nothing left to invoke,
      not popped up and as checked as it was. A damaged file or record is
      dropped with one warning. Pictures only the server held (an
      `image://` other than a theme icon) are saved as they first show, from
      the item drawing them (`grabToImage`, the size drawn), as
      `<uid>-image.png` and `<uid>-appIcon.png` in the cache dir
      `notifications/`, and those of notifications no longer saved are
      deleted; one never shown is not kept. A reload hands live
      notifications over too, and one already read back by app, summary and
      body becomes the live one.
    - `center/` is the notification center (`qs ipc -c shell call panels
      toggle center`), GNOME's layout, dropping down from the middle of the bar with
      a short fade and slide: notifications on the left (40em, wider than
      GNOME's 29em, which read long and narrow), Do Not Disturb and Caffeine
      switches, Collapse all and Clear (which also closes it) below, and `Calendar.qml` on
      the right (locale's first weekday, ISO week numbers, arrows or wheel for
      months (`WheelSteps`, as every wheel), the date returns to today) with the weather under it, left out
      where the screen is too short for both. Opening it puts the popups away. Notifications are grouped
      per app the way end-4's dots do (`NotificationGroup`,
      `NotificationItem`): one card with the app's icon and its count as a
      badge on it (no name), always three lines tall with what it holds
      centred beside the icon, so the stack is even: a lone notification its
      title and age over two lines of body, a group a line for each of its
      newest three, each with its own age. The arrow, a sign rather than a
      button, in a column every card keeps so the ages line up, shows only when expanding shows more
      (buttons, progress, or a cut-off title or body) and overhangs the first
      line rather than setting its height. Expanded, the card keeps 16 px off its
      top and bottom, and in a group each notification gets an inset card
      (`Theme.padding` inside) laid out as a popup is: its image at the top,
      the title to two lines and the body to four, with an arrow of its own
      as a sign, and a click on a cut-off one opens it rather than running its
      action; a lone one's title and body show whole, right under each other. Collapse all, beside Clear
      while any group is expanded, collapses every one. Opening and
      collapsing ease as a popup's do, each holding the whole text until its
      card has eased down, and only then laid out anew, so nothing bounces;
      the text eases between centred and the top as the height does, the
      icon level with its title throughout, so nothing jumps. A lone notification with a picture shows it in the icon's place,
      the app's icon a badge on it unless the picture is that icon (an app
      icon sent without an image is Quickshell's `image` too), as popups do
      (`NotificationIcon`). Only a card a click expands has a close
      cross, under the pointer in its first age's place
      (`NotificationStamp`). The pointer is a hand where a click expands or
      opens something, an arrow where it only dismisses. A click on a group with more to show expands and
      collapses it; on a lone one with nothing more it runs the default
      action, or dismisses it without one; in an expanded group of several a
      notification's click runs its own, or dismisses it. Right click or a
      swipe dismisses the group, or once expanded, one notification. Critical
      ones are tinted red (`Theme.criticalCard`) rather than outlined. The list grows with its
      notifications up to the screen's height, then scrolls. Mouse only, and unlike the launcher
      it is smooth: the list drags and flicks with Qt's overshoot, a wheel
      notch glides 120 px (Qt's own moves the 15 px Wayland reports), and
      groups animate their height, but only once laid out (250 ms in), since text
      wraps a frame or two after a card is made and easing that slid it as the
      center opened. Escape or a click
      outside closes it, and its `quickshell:center` layer rule dims behind
      it. The popups and the center cast libadwaita's window shadow
      (`common/Shadow.qml`, Qt's `RectangularShadow`), and their expand
      signs use libadwaita's arrow (`common/ExpanderArrow.qml`, Adwaita's
      `pan-down-symbolic` as a `Shape`).
  - `hyprtoolkit.nix` themes hyprtoolkit (`~/.config/hypr/hyprtoolkit.conf`),
    which hyprpolkitagent ≥ 0.2 and hyprland-guiutils' dialogs (app not
    responding, permissions) draw with, as libadwaita's dark style on the darker palette: window
    background, buttons and borders as the foreground at 10 % and 15 % made
    opaque, Adwaita Sans, Papirus-Dark, radii 9/12. The accent is `blue_5`,
    since hyprtoolkit writes dark text on an accent lighter than OkLab 0.5.
  - hyprlock talks to fprintd itself (`auth:fingerprint`, on when
    `services.fprintd` is), so the NixOS half turns `fprintAuth` off for
    hyprlock's PAM service.
  - Every lock (idle, sleep, the power menu's Lock) goes through
    `loginctl lock-session`, so hypridle's `lock_cmd`, which never starts a
    second hyprlock, is the only thing that runs it.
  - An idle lock comes after the screens fade to black (`idle/`, the
    `quickshell:idle` layer on every screen, on the overlay layer and taking
    no input): hypridle's listener 10 s before its lock runs `qs ipc -c shell
    call idle fade 10`, and the same listener's resume `cancel`, so any input
    during the fade brings the screens back. hypridle stays the one clock and
    the one watcher of input, and without a shell the lock simply comes. hyprlock
    is that same black (the palette's `dark_5`, no picture), so the lock
    follows the fade without a flash. Sleep and the power menu lock at once.
  - Caffeine (the center's switch, `Caffeine`, `qs ipc -c shell call
    caffeine toggle|set|active`) is the `caffeine.service` user unit,
    `systemd-inhibit --what=idle` part of the session target: hypridle honours
    logind's idle inhibitors, so nothing locks or blanks while it runs, and a
    unit outlives a shell restart. Sleep is not inhibited. The shell reads
    `systemctl --user is-active` as it starts, after a toggle and every 5 s
    (2 s while the center is open), since the bar's cup shows it always and a
    unit can stop by itself.
  - The OSD (`osd/`) shows what just changed on the focused monitor, on the
    overlay layer, for 1.5 s (fading in over 120 ms and out over 200 ms), never taking a click: by its right edge a
    slim upright slider (level filling from the bottom, past 100 % in the
    warning colour, the number above and the symbol below) for output
    volume and mute and brightness, and at the bottom centre, 4em up as GNOME
    Shell's, a pill with a symbol and a word for microphone
    mute, a new default output or input, and Caps Lock. `Osd` is the backend,
    changes as they are made rather than states as they are found: each
    `Watch` takes in the first value of what it watches, and any arriving
    within 500 ms of its key (the node's name) or readiness changing, so the
    shell starting, PipeWire coming back and a new output's own volume show
    nothing; each `DeviceWatch` shows a default device only once it settles
    (400 ms) and differs from the last one it knew, so an unplug that leaves
    no default for a moment shows only where it lands. Nothing shows for the
    output's level while its popup is open. Brightness is `Brightness`, every
    backlight from `backlight-watch` (`scripts/backlight-watch.sh`: `udevadm
    monitor` on the backlight subsystem, since the kernel sends a change
    uevent for every set however it is made, a line `name brightness max;`
    per change), the one that changed showing; Caps Lock is `CapsLock`,
    `hyprctl devices -j`'s main keyboard read when Hyprland's
    `input.keyboard.key` Lua event sees the Caps Lock key (66) go up and
    dispatches `quickshell:caps-lock` (`quickshell.nix`), since Hyprland
    reports no lock changes, and read again 150 ms later. A second bind on the volume and
    brightness keys dispatches `quickshell:osd-volume` /
    `quickshell:osd-brightness` (`bindings.nix`), so a level at its end still
    shows when the key changes nothing; a bind of its own, since Hyprland runs
    a bind that dispatches a global again on release. `Osd.settling` says it is still
    taking in, for tests.
  - The screenshot binds call one `writeShellApplication` (`scripts/freeze-region.sh`,
    `copy|save`) that carries its own runtime inputs.
  - Binds reference configured packages (`config.programs.wezterm.package`,
    `config.programs.quickshell.package`, …) rather than `pkgs.*`.
  - The HM half reads `osConfig` (compositor package, xkb layout, fprintd,
    NetworkManager), so it requires the NixOS half.
- **`neovim/`** ships a Lua config in-tree. `homeManager.neovim` symlinks
  `xdg.configFile."nvim".source` to the module dir, or to the home-manager
  option `neovim.outOfStorePath` (a checkout) for live editing. git (for
  `vim.pack`), LSP servers, formatters, `gcc`, `tree-sitter`, `fzf` and, on
  Linux, `wl-clipboard` (for `unnamedplus`) are
  `programs.neovim.extraPackages`,
  so they are on nvim's PATH only; ripgrep and fd come from `programs.ripgrep` /
  `programs.fd` for the shell too. Per-server LSP overrides live in `after/lsp/`.
  home-manager's own `init.lua` (providers off) is sideloaded through the
  wrapper (`sideloadInitLua`), since the whole `~/.config/nvim` is the module's.
  Neovim 0.12+ `vim.pack` is the plugin manager; `nvim-pack-lock.json` is
  committed and pins every plugin:
  - in a writable checkout, `vim.pack` reads and writes it in place;
  - from the read-only store, `init.lua` points `vim.pack` at a copy in
    `~/.local/share/nvim/nvim-pack-config/` and, whenever the committed
    lockfile changes, reseeds that copy and runs
    `vim.pack.update(nil, { target = "lockfile", force = true })`.
  - To update plugins from a store install: `:lua vim.pack.update()`, then
    copy `~/.local/share/nvim/nvim-pack-config/nvim-pack-lock.json` into
    `modules/features/neovim/` and commit. Run `:TSUpdate` afterwards.
- **`pi-agent/`** installs `pi-coding-agent` from `inputs.nixpkgs-unstable`
  directly (not `pkgs.unstable`, which the mac lacks). nixpkgs' wrapper prefixes
  ripgrep and fd onto pi's PATH; the feature's own wrapper suffixes git
  (worktree isolation, the commit skill) and node (npm install scripts), so a
  project shell's versions win. It writes `settings.json`, `APPEND_SYSTEM.md`,
  the `commit-style` skill, a `bell` extension (BEL on a finished run or a
  prompt, which tmux marks on a background window) and a `tmux-session`
  extension (the session file in the pane option `@pi_session`) into `~/.pi/agent` (pi
  ignores XDG), merging its
  home-manager option `piAgent.settings` over the defaults; both hosts set it
  to pin their provider, model and thinking level. pi packages
  (`@tintinweb/pi-subagents`, `rpiv-ask-user-question`, `rpiv-todo`) are
  pinned in `packages` and installed by pi itself with nixpkgs' `npm`
  (`npmCommand`) into `~/.pi/agent/npm`. home-manager's own
  `programs.pi-coding-agent` is not used: release-26.05 lacks it.

### Profiles (`modules/profiles/`)

Profiles are ordinary aspects that import other aspects. A host chooses which
to take.

- `base` — nixos imports `boot doas documentation git home-manager journald
  locale network neovim nix nixpkgs packages podman unstable-nixpkgs
  users` and wires `homeManager.base`; `homeManager.base` imports `git
  pi-agent tmux users xdg-user-dirs zsh`.
- `workstation` — nixos imports `display-manager fonts gtk hyprland plymouth
  sound`; `homeManager.workstation` imports `bluetooth cursor desktop-apps gtk
  hyprland neovim qt wezterm`. Its NixOS half pulls in the HM half.

### Theme (`modules/theme/`)

`palette.nix` declares `palettes` and is the canonical example of a top-level
value option. `fonts` is nixos; `gtk` is nixos + homeManager; `cursor` and
`qt` are homeManager. `gtk` recolours apps with the palette's darker surfaces:
GTK4 through libadwaita's `:root` variables (dark style only), GTK3 through
adw-gtk3's `@define-color` names, both in the user `gtk.css`. Qt's adwaita-dark
style keeps its own colours.

### Hosts (`modules/hosts/`)

Each host is a directory; `imports.nix` declares the host and its aspect
list, sibling files contribute to the same
`flake.modules.nixos."nixosConfigurations/<name>"` aspect, and `home.nix` /
`monitors.nix` to `flake.modules.homeManager."nixosConfigurations/<name>/home"`.

Hardware settings (firmware, fstrim, fwupd, zram, microcode, graphics, bluetooth)
stay in each host's `hardware.nix`, even when hosts repeat them: hardware is
individual by nature, so it is not factored into a shared aspect.

Both hosts' `home.nix` carry the homelab tooling: `just`, `helm`, `virtctl`
(`kubevirt`), `kubelogin` (`kubectl oidc-login`), `programs.gh` (also git's
credential helper for github.com), `piAgent`
settings, and an ssh `loft01` host (10.0.0.1) that forwards local 6443 to the
k3s API.

- **`thonkpad`** — imports `base workstation gaming`. Intel laptop:
  microcode, firmware, bluetooth, graphics + `intel-media-driver`/`vpl-gpu-rt`, fstrim, fwupd, zram,
  `thermald`, TLP battery thresholds, UPower (the bar's battery), disko, `treefmt`, mDNS and ephemeral UDP
  ports open for Chromecast discovery.
- **`desktop`** — imports `base workstation gaming moonshine`. AMD desktop:
  microcode, firmware, RX 6700 XT graphics, fstrim, fwupd, zram, ZSA keyboard udev rules
  (keymapp), disko, hyprmoncfg profiles `default` (both monitors), `left-only` and `right-only`,
  nix-index, ssh hosts for github.com and rsync.net,
  Hyprland startup apps pinned to monitors, host-specific app list.

## External consumers

The mac (a separate nix-darwin flake) imports `modules.homeManager.{wezterm,
neovim, pi-agent}`. Keep those aspects platform-neutral (no
Linux-only packages without a guard), and expose anything the mac must set as
an option of the aspect.

## Build, check, format

```bash
host=thonkpad

sudo nixos-rebuild switch --flake ".#$host"
nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel"

nix build --no-link --print-out-paths ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"

nix flake check          # runs the checks below
nix fmt                  # formatter = nixfmt-tree
```

`modules/flake/checks.nix` defines, via `perSystem`:

- `checks.<system>.format` — runs `nixfmt --check` over every `.nix` in the
  repo. Keep the tree `nixfmt`-clean.
- `checks.<system>.eval` (Linux systems only) — instantiates
  `system.config.system.build.toplevel.drvPath` for every NixOS host and
  installer, forcing the whole derivation graph without building it (the
  string context is discarded).

`modules/features/hyprland/quickshell.nix` adds:

- `checks.<system>.qmllint` (Linux) — `qs-lint` (`scripts/qs-lint.sh`) over
  every host's built shell: qmllint from the Qt Quickshell was built with,
  failing on any warning. It writes the `qmldir` files Quickshell makes for
  `qs.*` imports itself, and mends Quickshell's type info in its copy
  (a `depends Quickshell` `_GlobalShortcuts` lacks, opaque stubs that hide
  core types, `FileView.adapter`'s unqualified type, `DBusMenuHandle`'s
  base), so only `uncreatable-type` (`PanelWindow`) is off. Output comes
  from `--json`, since the text output drops some files' warnings while still
  failing. Fix what it finds; where qmllint is wrong, a
  `// qmllint disable <category>` … `enable` pair around the lines.
  It then runs `qs-design-lint` (`scripts/qs-design-lint.sh`), the design
  standards as far as the source shows them: a colour that is not Theme's
  (a literal, `Qt.rgba`, a `Qt.tint` of anything but Theme), a radius typed
  out, a `ColorAnimation` over anything but `Theme.fade`, one inline
  component name in two files or shadowing one in `common/`, and `flatMap`.
  What a file does on purpose is listed in the script with why.
- `checks.<system>.notification-markup` (Linux) — `qmltestrunner` over
  `tests/tst_markup.qml`: what the notification body filter
  (`notifications/markup.js`) keeps, drops and escapes.
- `checks.<system>.qs-test` (Linux) — builds the qs-test package, so
  `writeShellApplication`'s shellcheck runs over `scripts/qs-test.sh`.
- `checks.<system>.notification-history` (Linux) — `qmltestrunner` over
  `tests/tst_history.qml`: the saved history read back, damaged files and
  records dropped, and its limits.

`nix flake check` skips `aarch64-darwin` unless `--all-systems`.

Agents always pass `--no-link` to `nix build`; never leave a `result` symlink
in the tree.

## Testing the Quickshell shell

Test the shell in a Hyprland of its own, never in the live session: the
host's Hyprland and its config, built from the checkout, nested in a headless
labwc, on its own D-Bus and its own `XDG_RUNTIME_DIR`. Nothing in it reaches
the running Hyprland, so neither hyprmoncfgd nor the live shell needs pausing,
and the user's screens, pointer, focus, notifications and tray are left alone.

- labwc only lends Hyprland a GPU: Hyprland needs a parent Wayland (or DRM)
  for its allocator, and binds `xdg_wm_base` 6, which headless labwc offers and
  sway and cage (5) do not.
- libseat is pointed at a seatd that does not exist, so Hyprland never asks
  logind for the DRM device, and the `HYPRLAND_NO_SD_*` variables keep it off
  the user's systemd environment and `hyprland-session.target`.
- The config is the host's `hyprland.lua` with its `hyprland.start` handlers
  and monitor rules dropped, plus the test's own monitors. Monitors are
  Hyprland's headless outputs, ids from 0 as on the real machine, so
  hyprsplit, `dim_around`, global shortcuts, workspaces, real windows and
  hotplug all behave as they do in the session.
- Input is `qs-input` (`scripts/qs-input.c`): one virtual pointer and keyboard
  held for the whole session, fed over a socket. A device per call (wtype,
  wlrctl) drops the seat's pointer or keyboard capability between calls, so
  Qt rebinds and loses the first events: clicks and keys went missing. Its
  keymap is the host's (`input:kb_layout`), so `super+shift+plus` is SUPER+?.

`qs-test` (`scripts/qs-test.sh`, the flake package `qs-test`) is the whole
session; agents set `QS_TEST_DIR` to a directory in their scratchpad, so each
has its own:

```bash
export QS_TEST_DIR=<scratchpad>/qs-test
qst() { nix run "path:$PWD#qs-test" -- "$@"; }   # or build it once and call the binary

qst up                         # the checkout's Hyprland config and shell (path:, so untracked files count) for this host
qst ipc panels open apps       # qs ipc call, with a timeout
qst key super+d                # through Hyprland's bind and the shell's global shortcut
qst type fire
qst key ctrl+n Down Return     # one key per argument
qst pointer 960 21             # hover, in layout coordinates
qst click                      # left, where the pointer is; or `qst click right 1889 20` (the tray)
qst drag 1631 112 320 0 250    # press at x y, move dx dy over ms, release: a swipe
qst wheel 3                    # notches, positive down
qst layers                     # the layer surfaces up: which panels are open, on which monitor
qst shot apps                  # numbered PNG in $QS_TEST_DIR/shots, path printed
qst shot crop "360,330 600x260"
qst shot dp2 DP-2              # one monitor
qst monitor add DP-2 2560x1440 1.25   # hotplug; `monitor remove DP-2` unplugs
qst monitor disable DP-2       # off as a hyprmoncfg profile turns it off; `monitor enable DP-2`
qst monitors                   # Hyprland's, disabled ones too
qst focus DP-2                 # focus a monitor, so the next panel or popup opens there
qst output 2560x1440 1.5       # the first monitor's mode
qst state                      # what the shell sees (JSON), with Hyprland's layers and monitors
qst state '.popups | map(.screen)'    # through jq
qst wait '.panel == ""'        # until it holds (5 s; `qst wait FILTER 10`), else fail printing the state
qst stays '.panel == "apps"' 2 # fail if it stops holding within 2 s (1)
qst reset                      # QS_TEST_MONITORS again with ids from 0, no windows, a fresh qs without state
qst run                        # sync, then every tests/scenarios/*.sh; `qst run FILE` for one
qst key super+Return           # real windows, for workspaces and the window switcher
qst tray                       # a tray item (a yellow star) with nested submenus (tests/tray.qml); `qst tray log` shows what it was told
qst x notify-send -a Discord loft01 hello   # anything else, inside the session (hyprctl talks to the test Hyprland)
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3   # the session's own PipeWire
qst pipewire restart           # or stop, start
qst backlight intel_backlight 40 [MAX]   # set a fake backlight and announce it, until the shell has it; `NAME remove` unplugs
qst camera open zoom [video1]  # a process named zoom holding a fake camera open; `close zoom`, `add video1`, `remove video0`
qst sync                       # copy edited QML in, restart qs, print its warnings; non-zero if it fails to load
qst problems                   # warnings and errors, less tests/known-warnings and this case's `expect`s
qst census                     # what the probe finds wrong on screen now (see below)
qst areas [REGEX]              # mouse areas and hovered items on screen by label (WINDOW/Type), in layout coordinates: x, y, label, enabled, clicks, hand
qst cursor 960 21 [hand]       # the cursor Qt sets there, and the item behind it when that changed; fails if not the one given
qst cursors [WINDOW]           # every enabled area there that takes a click and asks for a hand gets one (BarWindow, LauncherWindow, …)
qst motion start               # record every visible item each frame; `motion stop` prints what moved, failing on a jump
qst fail cliphist exit         # the shell's cliphist fails (or crash, missing, garbage) until `fail cliphist off` or a reset
qst expect [--may] 'hyprmoncfg'   # this case must (or may) log a warning matching it
qst actions                    # what the session tried to run on the machine
qst lint                       # the qmllint check, on the checkout
qst down                       # kills everything the session started; deletes it and the test shell's state
```

The session reaches nothing real: it has its own D-Bus and runtime dir;
`systemctl`, `loginctl`, `pw-play`, `xdg-open`, `nixpkgs-run` and
`hyprmoncfg` are fakes that log to `qst actions` (`hyprmoncfg status` replays
the live profiles); `systemd-run --scope` logs and runs the app in the test
session, so the launcher's apps open there; `hyprctl` is the test Hyprland's,
logging dispatches and reloads, with `hl.dsp.exit()` only logged; cliphist
reads a copy of the database. The config dir is the user's, symlinked, except
`hypr/` (the test's) and `hyprmoncfg/`; profiles to fake go in
`$QS_TEST_DIR/cfg/hyprmoncfg/profiles`. Every qs it starts has a fake battery at 76 %
(`bar fakeBattery`), so the bar shows all it can on any host; `qst ipc bar
realBattery` drops it (`bar fakeVolume` still stands in a made-up sound
server, `realVolume` drops it).

The session has its own sound server, a PipeWire on `tests/pipewire.conf`
and a WirePlumber with no hardware, logind or portal (`tests/wireplumber.conf`),
their state in the session and no system bus: null outputs Speakers (the
default, at 64 %), Headphones and HDMI / DisplayPort, test-tone microphones
Microphone (the default) and Headset Microphone (`audiotestsrc`, real
`Audio/Source`s), and a virtual Noise Cancelling source. `wpctl`, `pw-record`,
`pw-cli` and `pw-dump` in the session reach it; `reset` starts it afresh.
`systemctl --user start|stop|is-active` keeps each unit's state in
`$QS_TEST_DIR/units`, as the shell reads Caffeine back. `backlight-watch`
and `camera-users` are the real ones, run on `$QS_TEST_DIR/backlight` and
`$QS_TEST_DIR/dev` (one camera, `video0`), and `udevadm monitor` replays
what `qst backlight` appends.

- `sync` copies over rather than rebuilds: the copy keeps the built `nix/`
  and weather icons. It restarts rather than hot-reloads: a reload keeps
  inline components' old types ("X is not a type") and only watches files the
  last load used. A change to Hyprland's config needs `qst down` and `up`.
- `qst pointer` is an absolute motion of the virtual pointer, as a tablet's:
  a warp (`hl.dsp.cursor.move`) moves the cursor but may not hover.
- Pointer coordinates are layout coordinates; screenshot pixels are those ×
  the output's scale (the shell draws at `QT_SCALE_FACTOR` 1.2 within them).
- Tray menus take no keyboard and close on a click elsewhere or on their icon,
  not on Escape.
- `notify-send -A` waits for the action; background it.
- A shot shows the cursor a surface asked for only once the pointer has
  moved over it after it mapped (a tray menu just opened): move it again
  before shooting a cursor. A drag's cursor shows mid-drag: background a
  slow `qst drag` and shoot while it runs.
- Shots sometimes carry thin grey lines at fixed places across the
  layout: capture artifacts of the headless outputs, not the shell.
- Animation: `qst motion start` and `stop` around what moves. Frames for
  the eye: background `qst x grim -s 0.25 <file>` shots about 35 ms apart, then
  `md5sum` to see which frames settled.
- Every window in the copy gets a `ProbeWindow` (`tests/ProbeWindow.qml`)
  naming the file it is declared in (`BarWindow`, `LauncherWindow`, an
  `Overlay`'s own file over `common/Overlay`) as it is copied in, since
  Quickshell lists no windows and its scopes' children cannot be read from
  JavaScript; the probe walks their items, and labels them `File/Type`.
- One `qst` at a time per `QS_TEST_DIR`: two runs in one session restart
  each other's qs and PipeWire, and leave a stale one holding its socket.
- A `fail`ed tool stays failing until `fail TOOL off`, a reset or the end
  of `run`; `off` only undoes what `fail` did.
- qs logs Qt's `qt.quick.hover.cursor` category in the session, which names
  the item behind each cursor change; `cursor` and `cursors` read it.
- Never `pgrep -f <pattern> | xargs kill`: the pattern is in the calling
  shell's own command line. `qst down` finds the session's processes by its
  runtime dir and D-Bus address in their environment.
- Quickshell keys its state and cache dirs by config path, so the test
  shell's are its own; `qst down` deletes only those.

### State and scenario tests

`qst state` is `tests/Probe.qml`, an IPC target `probe` that qs-test adds to
the session's copy of the shell (never the built one): the open panel, the
screens and the Hyprland monitor each resolves to, the focused monitor,
workspaces with the label the bar gives them and their window count, windows, and every popup with
the screen it is on, the notification `history` (app and summary, newest
first), `dnd` and `unchecked`, the volume (percent, muted, output), the default `input`,
the `osd` showing (with its screen), `osdShown` (shows so far) and
`osdSettling`, `brightness`, `caps`, `privacy` (`mic` names, and `screen` and
`camera` names or null while unused), `caffeine`, `tray` (the items' ids), `field`
(the text field up, the launcher's search) and `problems`, plus `layers` (`"DP-1 quickshell:bar"`) and `hypr`
(`hyprctl monitors all`). Something a test needs to see goes in the probe,
read through the shell's own singletons rather than worked out again.
`wait`, `stays` and `state` fail with "qs is not running" once qs has
crashed, and `problems` says so too.

Every snapshot also checks the shell as a whole, so each scenario checks it
at every step. `problems` is the probe's census of every window: text with no
room left (it vanished) or under 8 pt, text below 3:1 against what is behind
it (Theme's faint colour and fading text aside), colours and radii that are
not Theme's (or half the size), an image shown without a source or failing
to load, a disabled mouse area still setting a hand, a card running off its
window, and a window that is not a layer surface. `invariants`
(`tests/invariants.jq`): an open panel has its layer and a layer its panel,
nothing on `FALLBACK`, popups only on real screens and five at most, hovered
only while popped up and one at a time, three per app past the popped up,
unchecked within the count, and a countdown never going back up without
popping up again. `wait` and `stays` fail on one that lasts 500 ms, since a
transition passes through some for a frame or two, and on the countdown at once.
What a type draws to its own scale is in the probe's `ownShapes`.

A case fails on any warning qs logs during it, less `tests/known-warnings`
(a regex, a tab and why: the session's environment, and Qt's ShaderEffect
warning on a scale change, quickshell#1530, until a fix lands) and what the case itself
`expect`s, which must then come; `pipewire stop` and `restart` expect
PipeWire's own. qs-test also fails a start where an `IpcHandler` target
in the source is not registered.

`tests/scenarios/*.sh` are regression tests, run by `qst run` in the session
(`notify-send` and `hyprctl` reach the test's, `qst` is on PATH) under
`set -euo pipefail`. Each `qst case "what should happen"` prints the case and
resets; the file sets `QS_TEST_MONITORS` for its cases, and stops at its first
failure with the case named and the state that failed. Assert with `wait`
and `stays`, never `sleep`: `run` refuses a scenario that sleeps unless the
line says why after `# sleep: `. `hotplug.sh` covers unplugging, disabling and
replugging under every panel, a tray menu and popups, every monitor going,
bursts and mode changes; `notifications.sh` the history: three per app once
their popups go, the five-popup limit, stack tags replacing in place, and Do
Not Disturb with transient and critical notifications, and what the bell counts; `workspaces.sh` windows opened while the shell starts; `osd.sh` what shows and what must not
(the shell starting, PipeWire restarting, a switch's new level, an unplugged
default, the popup open, backlights coming and going, the media keys at a
level's end, Caps Lock both ways, its monitor going); `privacy.sh` microphones
real and virtual, meters, sink monitors, PipeWire going and coming back,
screen casts, cameras through PipeWire and held from `/dev` (a short probe,
PipeWire's own hold, one plugged in later, one unplugged in use);
`caffeine.sh` the unit started and stopped from the shell and elsewhere, the bar's cup turning it off, and
a shell restart. `design.sh` brings every panel, the bar, popups of
every kind, a tray menu, the volume popup, the OSD and the privacy tooltip
on screen, on a scaled monitor too, for the census; `cursors.sh` sweeps the
bar and every panel and checks a closed hand mid-drag; `binds.sh` presses
every bind that dispatches a global and checks each opens a panel of its
own and closes it; `launcher.sh` types as the launcher opens on a fresh
shell and times the open; `failures.sh` makes the shell's tools fail (`qst
fail`); `motion.sh` expands and collapses a center group and fades the OSD
under `qst motion`. Behaviour that broke once gets a case; check that
the case fails without the fix (a `git worktree` of `HEAD` with the new
`tests/` copied in, run with `QS_TEST_REPO` pointing at it).

What Hyprland does that tests run into:

- With no monitor on, Hyprland puts up a headless `FALLBACK` output; Quickshell
  lists it, so the probe's `screens` holds it.
- Removing any monitor focuses the first one.
- A connector gets back the id it last had unless another monitor holds it,
  and otherwise the lowest free one, which it keeps from then on; after
  `FALLBACK` held 0, a monitor plugged back in takes 1 for good. `reset` holds
  ids with fresh placeholder outputs to give the test's back 0, 1, ….
- A monitor rule without `disabled = false` leaves a disabled monitor off,
  so qs-test writes it in every rule.
- Going to and from no output at all, Qt moves windows to a placeholder screen
  for a moment, and each warns "Layershell screen does not correspond to a
  real screen"; `problems` drops those only right after Qt's "creating
  placeholder screen".
- In jq a pipe binds loosest: `(.popups | map(.screen)) == [...]`, not
  `.popups | map(.screen) == [...]`.
- `qst shot` of the whole layout renders at the highest monitor scale, so
  pixel offsets differ from layout ones; shoot one monitor (`qst shot NAME
  DP-1`) to crop.
- The brightness keys run the host's brightnessctl, which reaches the real
  backlight from the test session too: drive the shell's
  `quickshell:osd-brightness` global and `qst backlight` instead. The volume
  keys' wpctl reaches the session's own PipeWire, so those may be pressed.

## Sharp edges

- **pi's `settings.json` is a read-only store symlink.** Anything pi would
  normally save itself (`theme`, `defaultProvider`, `defaultModel`,
  `defaultTools`, `packages`, `defaultProjectTrust`) fails to write and reverts
  on restart; set those through the home-manager option `piAgent.settings`
  instead. pi's own files (`auth.json`, `sessions/`, `npm/`) are unaffected.
- **pi themes cannot paint the screen background.** The theme format has no
  global background token; only the per-box `*Bg` tokens exist. The backdrop is
  the terminal's, i.e. wezterm's Adwaita Darker background.
- **Formatters/checks are per-system.** A new `perSystem` definition merges;
  don't redeclare `systems`.
- **`stateVersion`** defaults to the nixpkgs release (NixOS and home-manager);
  do not bump it without understanding the migration implications.
- **`networking.hostId`** is derived from the hostname hash. Renaming a host
  changes it.
- **The hyprland HM module depends on `osConfig`.** Importing only
  `modules.homeManager.hyprland` without the NixOS half will fail.
- **Hyprland session services only run under Hyprland.** `wayland.systemd.target`
  is `hyprland-session.target` for the whole user; a service meant for another
  compositor needs its own target.
- **`boot` and `systemd-boot` conflict by design** — `systemd-boot`
  `mkForce`s GRUB off; a host would add it on top of `base` (none does now).
- **The `modules` flake output is not a standard output.** Nix warns about it;
  it is intentional and required for external imports.
- **`skinke.net` resolves through the `wg0` NetworkManager profile, which this
  flake does not own.** The profile carries `ipv4.dns 10.0.0.1` and the route-only
  domain `~skinke.net`, so those names go to loft01's resolver instead of the
  public one. It is hand-made in `/etc/NetworkManager/system-connections`:
  `nmcli connection modify` only edits the keyfile, so a change needs
  `nmcli connection up wg0` (or `nmcli device reapply wg0`) to reach
  systemd-resolved. With the tunnel down, the global `~.` silently answers from
  public DNS.
- **Two nixpkgs channels.** Default `pkgs` comes from `nixpkgs`;
  `pkgs.unstable` comes from the `unstable-nixpkgs` overlay. Prefer the
  default unless a package needs unstable.
- **Never hardcode the username.** Read `config.identity.username`.
