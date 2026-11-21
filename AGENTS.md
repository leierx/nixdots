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
TODO.md                   a plain bullet list (no headings): upstream candidates, leads to chase, what is left open

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
| `bluetooth.nix` | homeManager | `bluetooth` | `bluetui` when the host enables `hardware.bluetooth` (via `osConfig`), the control centre's Bluetooth Settings |
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
    config reload restarts it) and hyprsunset (the control centre's night
    light, started with `--identity`, untinted). No nm-applet: the control
    centre does its job.
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
    center from the bar's clock, the OSD, the control centre) are a [Quickshell](https://quickshell.org)
    shell in `quickshell/`, wired by `quickshell.nix`: one `quickshell.service`
    session daemon (restarted when the shell changes, via `X-Restart-Triggers`,
    and a second after a crash, with no start limit, so a crash loop through a
    burst of hotplugs never leaves the session without one).
    Quickshell comes from `pkgs.unstable` (0.3.2), since 0.3.1 fixed crashes on
    freed objects in a `ScriptModel`, which the notification lists hold. Each
    component is its own directory owning its windows, widgets and sizes, and
    `shell.qml` only instantiates them. `common/` holds what several share:
    the widgets of the design standards below, `Theme`, `Symbols` (every
    Material Symbols path), `Panels` (the one open panel by name: opening one
    closes the others, and nothing opens while no monitor is on, where it would
    land on `FALLBACK` holding the keyboard; IPC `panels open|close|toggle
    <name>`: `apps`, `clipboard`, `monitors`, `windows`, `nixpkgs`, `center`,
    `shortcuts`, `power`, and per screen `controls:DP-1` and
    `tray-overflow:DP-1`), `Overlay` (the full-screen layer a panel lives in:
    a click off its `card`, or a window elsewhere taking the keyboard, closes
    it; it holds the keyboard exclusively only until it has it, or a window
    clicked on another monitor never got it), `ClickAway` (a layer under the
    windows on every screen, taking input only while a panel is open, so a
    click on bare desktop closes it), `Screens` (the screens less Hyprland's
    `FALLBACK`, and the focused one), `Time`, `StateFile`, `Command` (a process
    whose failure, even to start, becomes a notification, or only a log line
    while `quiet`), `Detached` (a `systemd-run --user --scope` per app, since a
    restart of the service kills its whole cgroup), `WheelSteps` (wheel events
    as whole notches) and `WorkspaceOwners` (hyprsplit's numbering, as the bar
    names a workspace).
    - Conventions for the QML:
      - Comments follow the repo rule strictly: none by default, no file
        headers, one line saying why, never what. What a component does is
        documented here, not in the QML.
      - Colours, fonts, radii and spacing come from `Theme`; only `Theme`
        reads `Colors`. A size that belongs to one component stays in it.
      - Shared pieces live in `common/` and are extracted at about three
        uses; a widget used in one file is an inline `component`, unless the
        file does several jobs, which each get a file of their own.
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
      - Quickshell sorts `SystemTray.items` by category and id, not by when
        they came (`TrayOrder` keeps that).
      - A picture sent as a bare path (`notify-send -i /file`) reaches
        Quickshell as a theme icon, `image://icon//file`; `Notifs.picture`
        reads it as the file.
      - A `Binding` with `when: !area.pressed` let its value through during a
        drag: what a press must hold is set in `onPressed` (`Slider`'s range).
      - Under a disabled ancestor a `MouseArea`'s own `enabled` still reads
        true, so a cursor bound to it shows a hand: set it explicitly
        (`Button`'s area takes the button's).
      - `Pipewire.preferredDefaultAudioSource` refuses a node Quickshell
        leaves untyped, a virtual source among them: `wpctl set-default`.
      - A `ShellScreen` dangles while its monitor goes, and every binding
        still reading it logs "attempted to use dangling screen object": a
        window per screen takes its name once, in `Component.onCompleted`.
      - Past a couple of dozen windows on a workspace Hyprland tiles some to
        negative sizes, and capturing one makes Wayland kill the shell
        (`wl_shm_pool` "Invalid stride"): no `ScreencopyView` of a window
        Hyprland reports smaller than nothing.
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
      - Quickshell.Networking exports a type named `Network`, which shadows a
        singleton of that name in any file importing the module: the shell's is
        `Net`.
      - Quickshell.Networking picks its backend once, as it is first used:
        NetworkManager not running then leaves it without one until the shell
        restarts. Restarting NetworkManager later is handled.
      - Quickshell asks NetworkManager for every access point at once, and
        the system bus allows 128 pending replies a connection: past about
        128 networks in range the rest are missing (TODO.md). qs-test's bus
        raises the limit.
      - Quickshell reads an MPRIS player the moment its bus name appears; one
        that fills in its properties after that is never read.
      - Firefox drops `mpris:length` from a new track's metadata while it
        plays (YouTube's next video) and sends it again only on a pause, so
        `Media.length` keeps the one last sent for the track.
      - hyprsunset's `temperature` getter keeps the last temperature through
        `identity`, so the shell keeps whether night light is on itself.
      - Bluetooth pairing without an agent pairs only what wants no code, and
        a failed `pair()` shows only as `pairing` ending without `paired`.
      - A `ScriptModel` with `objectProp` keeps a delegate whose key stays and
        hands it the new value (`dataChanged`): lists rebuilt from bindings
        keep their state (an open menu, a typed password) only through it.
    - `Theme` is libadwaita's dark style 1:1 on the darker palette, designed
      at scale 1 (1920x1080): its named colours, the foreground at
      libadwaita's alphas for hover, selection, borders and buttons, its type
      scale, radii and shadows. Hyprland's per-monitor scale takes care of a
      dense screen; the home-manager option `quickshell.scale` (default 1, the
      desktop's 27" 1440p monitors 1.2) enlarges the shell alone, as
      `QT_SCALE_FACTOR`, which apps and links the shell opens get removed.
    - Design standards: one way to do each thing, and what departs from it is
      listed under Exceptions with why. `qs-design-lint` (in `qst lint` and
      the qmllint check) fails what the source shows; the probe's census what
      only shows on screen.
      - Pieces, all in `common/`: a bar item is a `BarButton`; a button a
        `Button` (`flat` on a surface, `checked` while what it opens is open,
        a `glyph` before its text, `expander` for a chevron after it); a round
        icon-only one an `IconButton` (34 px with a 20 px glyph, or 24 px with
        16 px in a row); every chevron an `ExpanderArrow`, turned by its
        `pointing` (`down`, `up`, `left`, `right`) and never by hand: down to
        up for what expands in place, right to down for what opens a menu
        under it; a level to drag a `Slider` (its range reaching past 1 while the level does, with a tick at 100 %, held still for a drag, which Escape puts back where it began); a scroll bar a `ScrollBar` (Qt's
        `ScrollIndicator`, 4 px, fading out unless `held`); a switch a
        `Switch`; a key a `Keycap`; a key that acts on a label underlined in it (`Theme.accessKey`); a text field a `TextField`; a row of a
        panel's list a `ListRow`; a press's feedback a `Pop`; what can be taken back a `Toast` (a pill with its button, five seconds, gone with its panel); an icon a
        `Glyph` of a `Symbols` path (an app's or tray item's an `IconImage`);
        anything floating a `Card` in an `Overlay` or a layer of its own, and
        only a `Card` casts the shadow.
      - Colour: only Theme's. Surfaces `bg`, `card` (on a panel) and the
        bar's `panel` black. Text `fg`; `fgDim` for what is secondary;
        `fgFaint` for what is empty; `fgStrong` only where `fgDim` is too
        faint (occupied workspaces, text on album art). The one accent is
        `accentBg`, never a light blue: on and checked, today, sliders, ticks,
        focus rings, progress and links. Red is `destructive` for text and
        outlines and `destructiveBg` for fills. A critical notification is
        marked one way: a 1 px `destructive` outline on its own popup, card or
        box, never on its group, and a collapsed group leads with its critical
        lines, each after an 8 px `destructive` dot. An outline that says "off" or "someone else's" is 1 px
        `fgDim`.
      - States: the foreground at 0 (flat) or 10 % at rest, 7 % for a row or
        15 % for a button under the pointer, 15 % selected and 25 % pressed or
        open: `button`, `hover` or `buttonHover`, `selected`, `buttonChecked`;
        cards `card` and `cardHover`. Keyboard selection is `selected`, so it
        reads apart from hover.
      - Shape: a pill or a circle is `radius: height / 2`; otherwise Theme's
        radius for the role: `smallRadius` (6) every list and menu row,
        keycaps and workspaces; `buttonRadius` (9) buttons, inset cards and
        pictures; `cardRadius` (12) popovers off a bar item and cards on a
        panel; `windowRadius` (15) panels and popups.
      - Borders and dividers: what floats has a 1 px `Theme.outline` and the
        shadow (`Card`), a critical notification's outline `destructive`; a focus ring
        is 2 px `accentBg`. A divider is 1 px `Theme.border` inside its
        container's padding, and only between two panes or between a list and
        its actions; everything else is parted by spacing.
      - Size: bar items 26 px with 18 px glyphs; buttons 34 px; a panel's list
        rows 36 px with 20 px symbols in a column of their own, the tray menu's
        32 px, the launcher's 50 px. Panels pad `Theme.padding` (12), menus 6,
        and keep `Theme.gap` (10) from the screen's edges; a popover under the
        bar sits the bar's `Window.height` plus `Theme.gap` down, centred on
        its button and kept on the screen. Panel widths are in em of the body
        font (`Theme.em`), after GNOME Shell's.
      - Type: `Theme`'s fonts only: `body`; `heading` for the titles of rows
        and cards; `caption` for ages and states under a name, and the bar's
        lettering; `captionHeading` for its numbers and badges; `title4` for
        panel and menu titles; `title2`; and one each
        for the launcher's `search`, the weather's `temperature` and the power
        menu's clock (`display`). Long text elides at a line limit. Words
        follow GNOME's HIG: header capitals for titles (the notifications our scripts send too), buttons, pills and menu
        items ("Collapse All", "In Use"), sentence case for subtitles, states,
        placeholders and bind descriptions; "…" only where more input follows (a placeholder that acts), never on a settings item ("Network Settings"); an estimate says about ("About 2 h 40 min left"); no text ends in a full stop, our own notifications' bodies too. Numbers take a narrow no-break
        space (U+202F, `Theme.unit`) before % and units ("76 %", "2 h 40 min"),
        degrees none ("5°"); a track's time is
        m:ss; a date is in the locale's order with the day unpadded ("Friday
        20 November").
      - Icons: every path is in `Symbols` (Material Symbols Rounded), filled
        for status and state at 20 px and below, outlined (`…Outline`) for
        large action tiles and launcher modes; 18 px in the bar, 20 px in
        panels, 16 px beside text in a row.
      - Motion: `Theme.fade` (150 ms) colours and opacity; `Theme.move` (200
        ms, `Easing.OutCubic`) moves, resizes, slides, expansions and turns
        (popups slide out `InCubic`); `Theme.open` (240 ms, `OutQuint`) and
        `Theme.close` (140 ms, `InCubic`) a panel growing out of what opened
        it and back; `Theme.tap` (100 ms) the dip of a `Pop`; `Theme.settle`
        (400 ms, `OutCubic`) what is slow on purpose (a battery filling, album
        art washing in, the logo's turn, a pill's ripple, a scroll bar
        fading). Keyboard selection never animates.
      - Hints and empty states: there are no tooltips, as every icon-only
        button is one GNOME uses the same way. A list that can be empty says
        so in one dim `body` line where its first row would be ("No results",
        "Looking for networks…"); the center's is its bell and title.
      - Behaviour: the pointer rule under the conventions above, and nothing
        shows only under the pointer (the HIG's rule): an action is there to
        see, or reached another way too. Escape and a
        click away close every panel; a right click only ever opens a menu (the tray's), never dismisses or mutes;
        the tray's menu takes no keyboard, as GTK's doesn't. The wheel steps in
        notches (`WheelSteps`), and only the center's list glides. Only the
        centred panels (launcher, shortcuts) dim the screen behind; popovers
        off the bar don't.
      - Exceptions: the bar is all black; the power menu has its own
        backdrop and 28 px tiles, and takes its keys without Alt, as nothing
        in it takes text; a launcher mode may carry an `accent`
        (nixpkgs' two blues); hyprlock follows its own config; `LayoutDiagram`
        draws outputs and their labels to scale. Kept against the HIG on
        purpose: the monitors mode's placeholder names what it lists
        ("Monitor layout…") rather than an instruction, since a layout is
        picked more than searched for; an occupied workspace differs from an
        empty one by colour alone (`fgStrong` over `fgDim`), as the current one
        has its own fill and a mark would crowd 26 px items; the media card's
        text sits over its album art, blurred and darkened and held to 3:1 by
        the census, and hyprlock's clock over the blurred screen, as GNOME
        Shell's lock does.
      - A new visual piece is drafted first: options shot in the test session
        for the user to pick from, then built from the pieces above, linted
        (`qst lint`), and given probe fields and a scenario where it has
        behaviour.
    - The shell is written like any Hyprland rice, so it works on other
      setups: the QML runs its tools by name from PATH (`cliphist`, `wl-copy`,
      `pw-play`, `notify-send`, `xdg-open`, `systemd-run`, `hyprmoncfg`,
      `wezterm`, `curl`, `nixpkgs-index`, `nixpkgs-run`, `hyprctl`, `systemctl`,
      `wpctl`, `camera-users`, `backlight-watch`, `nmcli`, `nm-connection-editor`,
      `brightnessctl`, `bluetui`) rather than store paths, an exception to the rule above;
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
    - What each component is for, and what its code does not say; the
      behaviour itself is in the QML and its scenarios.
      - `launcher/`: one `LauncherWindow` and a `LauncherMode` per feature,
        each opened by its own global shortcut (`quickshell:launcher-<name>`):
        SUPER+D `apps`, SUPER+V `clipboard`, SUPER+P `monitors`, SUPER+Tab
        `windows`, SUPER+N `nixpkgs`. A mode sets its `rows` (each with a
        unique `key`, which keeps delegates as a search changes), the `fields`
        searched (`search.js`: every word as a substring, or in a loose field
        its letters in order, or else, from four letters, a word of the text
        it begins with but for one slip, ranked below both), a `glyph` or `image`, an optional `accent`,
        `preview` and own `find`. The card opens at full height and centred,
        so it holds still while typing; keys go round, the wheel stops at the
        ends. `apps` orders equal matches by `AppUsage` (frecency as one
        number per app, so nothing decays) and warms every icon at startup,
        since an icon Papirus lacks costs thousands of stats. `clipboard`
        decodes counts and thumbnails once per clip into Quickshell's cache,
        pruned to what cliphist lists, also at startup, after cliphist's wipe.
        `monitors` draws each hyprmoncfg profile from its file
        (`LayoutDiagram`), the recommended one first, and reloads a second
        after a burst of hotplugs. `windows` lists wlr-foreign-toplevels, on
        Hyprland in focus order with each one's workspace as the bar names
        it, and previews them live (no `ScreencopyView` of a window Hyprland
        squeezed below nothing). `nixpkgs` searches nixos-unstable's 130 000
        packages from `nixpkgs-index`'s TSV in columns with its own loop and
        memo, matching as typed only, since a slip pass would cost one over
        every row on each key, and runs one with `nixpkgs-run`.
      - `nixpkgs-run` builds `github:NixOS/nixpkgs/<rev>#<attr>` with a
        progress card (`nixpkgs-progress.jq` over nix's internal-json log) under
        Papirus' `nix-snowflake` (`-n`, as are its failures),
        then runs the program in a transient `systemd-run --user` service
        sandboxed by systemd alone: `ProtectSystem=strict`, `PrivateTmp`, a
        writable tmpfs over `$HOME` and `$XDG_RUNTIME_DIR` (the user
        manager's implied `PrivateUsers` keeps it off `/proc/<pid>/root`), only
        PipeWire, X11 and the GTK, fontconfig and cursor settings bound back
        in, and the nix daemon and both D-Bus buses out of reach. Wayland
        comes through a socket of its own from `security-context`, so
        Hyprland hides every protocol that could type into or capture other
        windows; X11 apps still share Xwayland. A program with a desktop entry
        runs on its own, anything else in wezterm, held open on a failure or a
        run under 5 s.
      - `shortcuts/` (SUPER+?): every Hyprland bind with a description, from
        `hyprctl binds -j` on each open, numbered and directional binds folded
        into one row, a submap's binds under the bind that enters it, media
        keys left out; in up to three balanced columns, shrunk whole only when
        none fits.
      - `power/` (SUPER+X or the bar's logo): five tiles, each one's key underlined in its label (`Theme.accessKey`, the HIG's access keys, pressed without Alt),
        Reload Hyprland and, on UEFI, Restart to Firmware; ending the session
        or the machine takes a second press within 5 s. Every action is a
        command, so `qst actions` shows what it would have done.
      - `bar/`: per screen, the logo and workspaces, the clock (opening the
        center) and the status button (opening the control centre) with the
        tray's chevron last. Workspaces are hyprsplit's `1 … n` for the
        monitor, then any other monitor's still on it, named after that
        monitor (`DP2-1`) by `WorkspaceOwners`, which remembers connectors by
        id across unplugs. Quickshell refreshes monitors only as one comes and
        drops windows opened on a workspace it has not loaded, so `Bar.qml`
        refreshes on those events and once more 300 ms after a burst. The
        status button shows, left to right, what records (`Privacy`), the bell
        while notifications wait unchecked or Do Not Disturb struck through,
        the VPN, the link in use, Bluetooth, a muted microphone, the volume
        and a laptop's battery; the wheel steps the volume. The tray folds every item behind one chevron in the order they
        came (`TrayOrder`, since Quickshell sorts by category and id);
        `TrayMenu` is libadwaita's popover menu, cascading as GTK's does,
        taking no keyboard and closing as the pointer leaves it.
      - `weather/`: MET Norway's forecast for the time zone's city
        (`/etc/localtime` placed by `zone.tab`, no lookup of the address),
        fetched every half hour and at once when the clock shows a suspend
        skipped one; MET's icons are fetched into `weather/icons/` by
        `quickshell.nix`.
      - `notifications/`: the notification daemon and its popups. `Notifs`
        keeps every notification as a `NotifEntry` until dismissed, holding it
        a second past its close so views slide it away whole. Popups stack on
        the monitor focused when each arrived, five at most, timing out under the pointer too (the center
        keeps them), held only out of sight or without a monitor; the
        countdown bar is the entry's own. Over a fullscreen window only
        critical ones pop up. A stack tag (`x-canonical-private-synchronous`,
        `x-dunst-stack-tag`), an update by id or the same app, summary and
        body within 2 s update a card in place. A flood is turned away at the
        door past 30 a second (critical ones apart) and summed up in one card;
        text is cut before anything lays it out, since a megabyte of it held
        the shell for seconds; each app keeps its newest three and all 100.
        Bodies keep only the markup the spec allows (`markup.js`). Sounds are
        elementary OS's, played with `pw-play`, at most one each 300 ms.
        `History` saves the list atomically to Quickshell's state dir (no
        transient ones, 7 days at most, `history.js`) with copies of pictures
        only the server held, drawn once off screen and grabbed into the cache
        under a uid per entry. Scripts use `qs ipc -c shell call notifications
        <toggleDnd|setDnd|dnd|count|clear|hidePopups>`.
      - `center/`: the notification center under the clock: notifications
        grouped per app (`NotificationGroup`), each card three lines tall so
        the stack is even, the calendar (ISO weeks) and the weather beside it
        where the screen has room. Opening it checks every notification and
        puts the popups away. Each card's close button sits after its age
        without the pointer over it (a group's on its first line), and every
        line keeps its room, so the ages line up. Clear hides them and offers
        Undo in a `Toast` for five seconds; `Notifs` dismisses what it held as
        the toast goes or the center closes (the `notifications clear` IPC at
        once). Its list glides on the wheel
        and flicks.
      - `controls/`: the control centre, GNOME's quick settings under the
        status button (SUPER+A): `Header`, `Levels` (output, input and each
        backlight), the `Pill`s the machine has (`Controls.toggles`: wired per
        device, Wi-Fi, VPNs, Bluetooth, night light, Do Not Disturb), a `Menu`
        under the row that opens it, `InUse` while something records and the
        `MediaCard` of the MPRIS player that played last. `ControlsPanel`
        stacks them, each menu in a slot of its own so one eases shut as the
        next opens, and scrolls past what the screen leaves under the bar. The
        backends are singletons: `Net` (Quickshell.Networking for Wi-Fi and
        wired, `nmcli` for VPNs and whether NetworkManager runs; a captive
        portal gets a card that goes when the portal does), `BluetoothDevices`
        (pairs, trusts and connects in one click; no agent, so a device
        wanting a PIN is sent to bluetui), `Volume`, `Microphone` (a virtual
        source is set through `wpctl`), `NightLight` (hyprsunset, kept in the
        state dir and put back when hyprsunset restarts), `Media` (the
        player, and its track's length), `Power`
        (UPower's display device) and `Privacy`: a capture stream linked from
        a microphone while audio flows (meters and passive filters left
        out), a video source a program made (the portal's screen casts), and
        a camera through PipeWire or held open from `/dev/video*` for half a
        second (`camera-users`). Names from devices and networks are made safe
        for one line by `names.js`.
  - `hyprtoolkit.nix` themes hyprtoolkit (`~/.config/hypr/hyprtoolkit.conf`),
    which hyprpolkitagent ≥ 0.2 and hyprland-guiutils' dialogs (app not
    responding, permissions) draw with, as libadwaita's dark style on the darker palette: window
    background, buttons and borders as the foreground at 10 % and 15 % made
    opaque, Adwaita Sans, Papirus-Dark, radii 9/12. The accent is `blue_5`,
    since hyprtoolkit writes dark text on an accent lighter than OkLab 0.5.
  - hyprlock talks to fprintd itself (`auth:fingerprint`, on when
    `services.fprintd` is), so the NixOS half turns `fprintAuth` off for
    hyprlock's PAM service.
  - hyprlock's background is each screen's own screenshot, blurred (3
    passes of 8) at brightness 0.6, with `contrast = 1` so brightness stays a
    plain multiply; `dark_5` only without screencopy. The clock is Adwaita
    Sans Bold at 64 pt over the date at 24 (centres 185 and 100), the field
    at −100 and the fingerprint prompt at −170. Its `fadeIn` (600 ms) crossfades from the
    screenshot to the blurred background, so the lock takes over from the
    screen as it was without an edge; `fadeOut` is off, since it would fade
    back to that screenshot and then cut to the desktop.
  - Every lock (idle, sleep, the power menu's Lock) goes through
    `loginctl lock-session`, so hypridle's `lock_cmd` is the only thing that
    runs hyprlock: `lock` (in `hypridle.nix`), which never starts a second
    one. It asks the shell how dark the idle dim is (`idle hold`, which also
    keeps it still and deaf to `cancel`, since hyprlock's screenshot takes it
    in) and, under a dim, starts hyprlock on a copy of its config in
    `$XDG_RUNTIME_DIR` whose brightness is 0.6 ÷ (1 − darkness), so every lock
    ends on the same picture, dimmed first or not, a lock mid-dim too. Once it
    has the lock, hypridle's `on_lock_cmd` (`idle locked`) drops the dim under
    it and keeps any from starting, so an unlock shows the plain desktop;
    `on_unlock_cmd` and `lock` once hyprlock exits (`idle unlocked`) clear it
    all, a hold that never got the lock too.
  - An idle lock comes after the screens dim (`idle/`, the
    `quickshell:idle` layer on every screen, black on the overlay layer and taking
    no input) to the lock's own brightness (to 40 % black for 0.6, worked
    out from hyprlock's settings), so the lock's fade-in only blurs:
    hypridle's listener 10 s before its lock runs `qs ipc -c shell call idle
    fade 10 0.4`, and the same listener's resume `cancel`, so any input
    during the dim brings the screens back. An unlock with no key or mouse to resume the
    listener (a fingerprint) clears it through hypridle's `on_unlock_cmd`. hypridle stays the one clock and
    the one watcher of input, and without a shell the lock simply comes, at
    0.6. Sleep and the power menu lock at once.
  - The OSD (`osd/`) shows what just changed on the focused monitor, on the
    overlay layer, for 1.5 s (fading over `Theme.fade`), never taking a click, in
    one place: a pill at the bottom centre, 4em up as GNOME Shell's. A level
    shows its symbol, the level filling across (past 100 % the share over it
    in the warning colour at the end) and the number, for every change
    of the output's or the input's level or mute and of brightness, wherever
    it came from (the keys, the control centre, another app); a symbol and a
    word show a new default output or input, and Caps Lock. `Osd` is the backend,
    changes as they are made rather than states as they are found: each
    `Watch` takes in the first value of what it watches, and any arriving
    within 500 ms of its key (the node's name) or readiness changing, so the
    shell starting, PipeWire coming back and a new output's own volume show
    nothing; each `DeviceWatch` shows a default device only once it settles
    (400 ms) and differs from the last one it knew, so an unplug that leaves
    no default for a moment shows only where it lands. Brightness is `Brightness`, every
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
    `copy|save`) that carries its own runtime inputs, and end with a
    notification from "Screenshot": the shot as its picture (a `file://` URI) and
    Papirus' `accessories-screenshot` as the badge (`-n`). A copy says
    "Screenshot Copied to Clipboard", its picture kept in
    `$XDG_RUNTIME_DIR/screenshots` until the next copy, under the stack tag
    `screenshot`, so a run of copies is one card. A save says "Screenshot
    Saved" with the path (`~` for home), untagged, so each file keeps its own
    card, with Open (also a click on the card) and Show in Folder
    (`xdg-open` on the file or its folder), waited on in the background.
    Both are transient and silent (`suppress-sound`), so they leave nothing
    in the history, and both take the popups' own timeout. Escape in slurp sends
    nothing; a failure sends a critical "Screenshot Failed" with why.
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
  Hyprland startup apps pinned to monitors, host-specific app list, and the
  shell a size up (`quickshell.scale = 1.2`) for its 27" 1440p monitors at
  scale 1.

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
  core types, `FileView.adapter`'s and `Bluetooth.defaultAdapter`'s unqualified types, `DBusMenuHandle`'s
  base), so only `uncreatable-type` (`PanelWindow`) is off. Output comes
  from `--json`, since the text output drops some files' warnings while still
  failing. Fix what it finds; where qmllint is wrong, a
  `// qmllint disable <category>` … `enable` pair around the lines.
  It then runs `qs-design-lint` (`scripts/qs-design-lint.sh`), the design
  standards as far as the source shows them: a colour that is not Theme's
  (a literal, `Qt.rgba`, a `Qt.tint` of anything but Theme), a radius typed
  out, a duration or font that is not a Theme token, an icon path outside
  `Symbols`, a shadow on anything but a `Card`, anything turned by hand
  rather than an `ExpanderArrow`'s `pointing`, one inline component name
  in two files or shadowing one in `common/`, `flatMap`, text ending in a full stop, an ellipsis on a settings item, and a plain
  space between a number and its unit.
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
qst run                        # every case, on sessions side by side (-j N; by default half the cores, fewer if memory is short), longest first
qst run chaos 'controls:VPN'   # a file, or its cases whose names match a regex
qst run --changed --fail-fast  # only the scenarios the checkout's changes reach, stopping at the first failure
qst run --failed               # the last run's failures first, then the rest
qst run -j 1 osd               # in this session alone
qst jobs [FILE[:REGEX]...]     # the jobs a run would take, in its order
qst timings                    # the last run's slowest cases and where the time went ($QS_TEST_DIR/timings.tsv)
qst key super+Return           # real windows, for workspaces and the window switcher
qst flood 3000 --urgency 2     # notifications by the thousand over D-Bus (--apps N, --summary/--body LENGTH, --rate N)
qst tray                       # a tray item (a yellow star) with nested submenus (tests/tray.qml); `qst tray log` shows what it was told
qst tray add first 4           # four items under the app id `first` (tests/trays.qml), each with a short menu; `tray remove first`, `tray clear`
qst x notify-send -a Discord loft01 hello   # anything else, inside the session (hyprctl talks to the test Hyprland)
qst x wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.3   # the session's own PipeWire
qst pipewire restart           # or stop, start
qst backlight intel_backlight 40 [MAX]   # set a fake backlight and announce it, until the shell has it; `NAME remove` unplugs
qst camera open zoom [video1]  # a process named zoom holding a fake camera open; `close zoom`, `add video1`, `remove video0`
qst camera add video1 locked   # plugged in root's alone, as devtmpfs makes it; `unlock video1` is udev handing it on
qst network wifi add Cafe 40 open # the session's NetworkManager (tests/networkmanager.py): wifi add SSID [STRENGTH] [SECURITY] [PASSWORD], wifi remove|strength|clear,
                               # wifi many 300 [PREFIX], wifi json JSON, device add|remove NAME [wifi|ethernet], cable NAME on|off, profile wifi|ethernet|wireguard|vpn NAME [SSID PSK],
                               # vpn NAME ok|fail|secrets, up NAME, connectivity none|portal|limited|full, switch on|off (the radio's hardware switch), delay MS, dump, stop|start|restart
qst battery 15 discharging 1800   # the session's UPower battery: PERCENT [charging|discharging|full|pending [SECONDS]], or remove
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70   # BlueZ (tests/bluez.py): ADDRESS NAME [ICON] [ok|pin|fail] [paired] [connected] [BATTERY]; remove ADDRESS, adapter add|remove, stop|start
qst player add spotify Spotify Playing [ART]   # an MPRIS player (tests/mpris.py), ART an image for its cover; status NAME Playing|Paused|Stopped, remove NAME, clear
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

The session reaches nothing real: it has its own D-Bus, system bus and runtime
dir; `systemctl`, `loginctl`, `pw-play`, `xdg-open`, `nixpkgs-run`,
`brightnessctl` (which sets the fake backlights, as the real one would reach
the machine's) and `hyprmoncfg` are fakes that log to `qst actions` (`hyprmoncfg status` replays
the live profiles); `systemd-run --scope` logs and runs the app in the test
session, so the launcher's apps open there; `hyprctl` is the test Hyprland's,
logging dispatches and reloads, with `hl.dsp.exit()` only logged; cliphist
reads a copy of the database. The config dir is the user's, symlinked, except
`hypr/` (the test's) and `hyprmoncfg/`; profiles to fake go in
`$QS_TEST_DIR/cfg/hyprmoncfg/profiles`. qs runs at `QT_SCALE_FACTOR` 1, the
standard, unless `QS_TEST_SCALE` says otherwise, and with `TZDIR`, which Qt
needs on NixOS to find the time zone (the user's systemd session sets it, a
shell may not). `bar fakeOutputs 1000` stands in a sound server with that
many outputs, some named to break things; `realVolume` drops it.

The session's system bus is a `dbus-daemon` of its own
(`DBUS_SYSTEM_BUS_ADDRESS` for everything in the session), so no test reaches
the machine's NetworkManager, UPower or BlueZ. Each case gets fresh fakes,
python-dbusmock templates run by `qs-dbusmock`: NetworkManager
(`tests/networkmanager.py`, written for what the shell and nmcli use, as
dbusmock's own is NetworkManager 0.9's: devices, networks in the air, saved
profiles, activation through Activating, a wrong password failing with no
secrets as NetworkManager's does, the radio, connectivity, WireGuard and VPN
profiles; `network stop` and `start` keep its state) with the desktop's wired
link and wg0 up and three networks in range unless `QS_TEST_NETWORK=none`;
UPower (`tests/upower.py`) with a laptop battery at 76 % discharging, so the
bar shows all it can on any host; BlueZ (`tests/bluez.py`) with an adapter
and nothing paired unless `QS_TEST_BLUETOOTH=none`. `nmcli` in the session is
the real one but for `connection up`: libnm will not register its secret agent
with a NetworkManager not run by root, so a wrapper asks the fake and waits as
nmcli does, saying "Secrets were required" for a profile set to want them.
MPRIS players (`tests/mpris.py`, seeking with `SetPosition`, a cover with `player add`'s ART, a new track's length dropped until a pause as Firefox drops it) sit on the session bus, one mock each, named
by `QS_MPRIS_NAME` as it starts, since Quickshell reads a player the moment its
name appears. hyprsunset runs in the session as it does in the user's.

The session has its own sound server, a PipeWire on `tests/pipewire.conf`
and a WirePlumber with no hardware, logind or portal (`tests/wireplumber.conf`),
their state in the session and no system bus: null outputs Speakers (the
default, at 64 %), Headphones and HDMI / DisplayPort, test-tone microphones
Microphone (the default) and Headset Microphone (`audiotestsrc`, real
`Audio/Source`s), and a virtual Noise Cancelling source. `wpctl`, `pw-record`,
`pw-cli` and `pw-dump` in the session reach it; `reset` starts it afresh.
WirePlumber gives a node made with `pw-cli create-node` no ports, so it lists
but never becomes the default; to take the default away, destroy a test
microphone (`pw-cli destroy test-headset-mic`) after making it the default.
`systemctl --user start|stop|is-active` keeps each unit's state in
`$QS_TEST_DIR/units`. `backlight-watch`
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
  `run -j N` (N > 1) uses sessions of its own, `$QS_TEST_DIR/w1` … `wN`, built
  once and brought up side by side, kept up for the next run and taken down
  by `down`; each has its own runtime dir, buses, PipeWire, fakes, cliphist
  copy and Quickshell state and cache dirs (keyed by its config path), its
  nixpkgs list copied from the newest any shell has fetched.
- A `fail`ed tool stays failing until `fail TOOL off`, a reset or the end
  of `run`; `off` only undoes what `fail` did.
- qs logs Qt's `qt.quick.hover.cursor` category in the session, which names
  the item behind each cursor change; `cursor` and `cursors` read it.
- Never `pgrep -f <pattern> | xargs kill`: the pattern is in the calling
  shell's own command line. `qst down` finds the session's processes by its
  runtime dir and D-Bus address in their environment.
- Killing qs alone leaves the watchers it runs (`camera-users`,
  `backlight-watch`) waiting on inotify for good, where systemd takes the
  whole cgroup: `stop_qs` kills the process group `setsid` gave it.
- Each `qst` is a `writeShellApplication`, which puts its own tools (the
  real `nmcli` among them) ahead on PATH: `enter` moves the session's
  `bin/` back in front every time, or the shell gets the real tools over the
  fakes.
- Quickshell keys its state and cache dirs by config path, so the test
  shell's are its own; `qst down` deletes only those.

### State and scenario tests

`qst state` is `tests/Probe.qml`, an IPC target `probe` that qs-test adds to
the session's copy of the shell (never the built one): the open panel, the
screens and the Hyprland monitor each resolves to, the focused monitor,
workspaces with the label the bar gives them and their window count, windows, and every popup with
the screen it is on, the notification `history` (app and summary, popped up, checked, `restored` from disk, its picture and the
pictures `kept`, newest
first), `dnd` and `unchecked`, the volume (percent, muted, output), the default `input` and the
`microphone` (percent, muted, `adjustable`, the input, every input by name),
the `osd` showing (with its screen), `osdShown` (shows so far) and
`osdSettling`, `brightness`, `caps`, `privacy` (`mic` names, and `screen` and
`camera` names or null while unused), `status` (each bar's status button: its glyphs by name, `Microphone`, `bell`, `dnd`, `vpn`, `network` and so on, and the battery's percentage or null), `controls` (the open
menu, the pills by key with their state, and each backend: `network`, `vpns`,
`vpnAsking`, `bluetooth`, `night`, `media`), `tray` (the items' ids, in Quickshell's order), `trays` (each bar's: whether its chevron
shows, how many icons wait behind it and their ids in the overflow's order), `held` (what Clear holds back for its Undo), `sliders` (every slider by name, its value and range), `results` (the launcher's first ten by title), `center` (the center's groups in view, each one's lines in its order), `field`
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
window, text drawn over other text (where the glyphs are, cut by clipping
ancestors), and a window that is not a layer surface. `invariants`
(`tests/invariants.jq`): an open panel has its layer and a layer its panel (a tray menu may sit over
the tray's overflow),
nothing on `FALLBACK`, popups only on real screens and five at most, three per app past the popped up,
unchecked within the count, the history within 100 and five popups, a
probe answered within 2 s (a shell held up by a flood or a list rebuilt over
and over is a frozen desktop; this one fails at once), and a countdown never
going back up without popping up again. `wait` and `stays` fail on one that lasts 500 ms, since a
transition passes through some for a frame or two, and on the countdown at once.
What a type draws to its own scale is in the probe's `ownShapes`.

A case fails on any warning qs logs during it, less `tests/known-warnings`
(a regex, a tab and why: the session's environment, and Qt's ShaderEffect
warning on a scale change, quickshell#1530, until a fix lands) and what the case itself
`expect`s, which must then come (once, though a restart in the case
starts a new log); `pipewire stop` and `restart` expect
PipeWire's own. It also fails where qs peaked past `QS_TEST_PEAK` MiB
(1024; read from `VmHWM`, as every case starts a qs of its own). qs-test
also fails a start where an `IpcHandler` target in the source is not
registered.

`tests/scenarios/*.sh` are regression tests, run by `qst run` in the session
(`notify-send` and `hyprctl` reach the test's, `qst` is on PATH) under
`set -euo pipefail`. Each `qst case "what should happen"` prints the case and
resets; the file sets `QS_TEST_MONITORS` for its cases, and a job stops at its
first failure with the case named and the state that failed. A job is a
top-level `qst case` up to the next (or a top-level loop of them, kept
whole), run after the file's lines before its first case: helpers go there,
and no case may use what an earlier one set. `run` hands jobs to whichever
session is free, longest first by the last time each took
(`~/.local/state/qs-test/jobs.tsv`, with the last failures in `failed`),
prints a line as each ends (a failure's last 15 lines and the path of its log,
`tests/FILE.LINE.log` in its session) and then the 15 slowest cases with
where the time went: reset (and its phases), waits, stays, the cases' own
work and snapshots, from `timings.tsv`. `--changed` maps the files `git`
sees changed to the scenarios that exercise them (`changed_scenarios` in
`qs-test.sh`, the one map), and runs everything for a file it does not
know. Reset brings PipeWire, the fakes and the monitors back side by side
once qs has gone. A case that times something against the machine (frame
by frame under `motion`, a launch against the clock, keys racing a panel
opening, or a shell that needs over a second to answer the probe even
alone) says `# alone: why` on a line inside it: its job runs with no other
beside it, all of them before the rest, so it sees the machine a lone
session saw; so does a job whose probe answer reached a second in the last
run. Assert with `wait`
and `stays`, never `sleep`: `run` refuses a scenario that sleeps unless the
line says why after `# sleep: `. `hotplug.sh` covers unplugging, disabling and
replugging under every panel, a tray menu and popups, every monitor going,
bursts and mode changes; `notifications.sh` the history: three per app once
their popups go, the five-popup limit, stack tags replacing in place, and Do
Not Disturb with transient and critical notifications, and what the bell counts, and a flood's sounds and repeats, and a picture sent as a bare path; `workspaces.sh` windows opened while the shell starts; `osd.sh` what shows and what must not
(the shell starting, PipeWire restarting, a switch's new level, an unplugged
default, the control centre open, the microphone's level and mute, backlights coming and going, the media keys at a
level's end, Caps Lock both ways, its monitor going); `privacy.sh` microphones
real and virtual, meters, sink monitors, PipeWire going and coming back,
screen casts, cameras through PipeWire and held from `/dev` (a short probe,
PipeWire's own hold, one plugged in later, one plugged in root's alone
until udev hands it on, one unplugged in use);
`controls.sh` is the control centre: the bar's button, SUPER+A,
Escape, the wheel and a right click; the status button's glyphs (what
records, the bell, Do Not Disturb, the battery); the header's screenshot,
lock and power menu; an In use pill raising its app's window; a Bluetooth
row's charge; which pills a machine gets
(NetworkManager, BlueZ, devices gone); NetworkManager stopping and starting
under it; Wi-Fi's saved, new (a wrong password, then the right one), given
up (its profile gone), vanishing and open networks, the radio and its
hardware switch, a captive portal's Sign In; VPNs down and up, wanting a
password and failing; a headset paired, trusted and connected in one click
and a keyboard wanting a PIN; night light kept through a restart and put
back in a hyprsunset started again; a backlight's slider and the centre's own levels and mutes showing the OSD;
the player that played last and a track length it drops; an output picked; PipeWire gone and back. Areas
are clicked by name: the probe adds an area's `objectName` (or its parent's)
to its label, and the centre names its pills, menu arrows, rows and actions
(`pill:wifi`, `menu:vpn`, `row:Pixel_7128`, `action:Network Settings`). `design.sh` brings every panel, the bar, popups of
every kind, a tray menu, the control centre with each of its menus (a
headset, a player and a backlight in), the OSD and an In Use pill
on screen, on a scaled monitor too, for the census; `cursors.sh` sweeps the
bar and every panel and checks a closed hand mid-drag; `binds.sh` presses
every bind that dispatches a global and checks each opens a panel of its
own and closes it; `launcher.sh` types as the launcher opens on a fresh
shell and times the open, and clicks a window on another monitor
with it open, then the bare desktop there; `failures.sh` makes the shell's tools fail (`qst
fail`); `motion.sh` expands and collapses a center group and fades the OSD
under `qst motion`. `idle.sh` runs the idle dim on two monitors under
`qst motion` to its depth, clicks the bar through it and cancels it, and
plays the lock command's part: a hold mid-dim and at its end, a cancel it
keeps out, nothing dimming while locked, and an unlock clearing a hold
that never got the lock. `history.sh` restarts the shell over a history
with a picture only the server held (sent by `gdbus`), clears it and finds
the saved pictures gone, starts on a damaged file and keeps transient ones
out; the probe's `historyFile` and `historyImages` are where it looks.
`chaos.sh` is what a hostile or broken client throws: floods of critical
notifications and of thousands of apps (`qst flood`, `qs-flood` over D-Bus
at thousands a second, where notify-send manages a hundred), megabytes of
text, icons that are no picture, panels toggled faster than they open, a
hotplug storm under an open panel, a workspace of 40 windows (`foot`), 60
outputs, 40 apps recording, damaged state files, and the tray and the
inputs: 30 tray items behind the chevron (a 640x480 screen too), the
overflow keeping their order as items come and go, 60 items churning under the open
overflow and a menu opened from it, 200 items scrolling in it and its monitor
going; 40 microphones real and virtual with 30 more outputs, the default
input switched by 30 clicks and 50 `wpctl`s, inputs coming and going and the
default one destroyed under the open input menu, mute and level hammered, both levels and the input's mute hammered with the OSD showing each change,
and PipeWire restarting under it; 300 networks with hostile names (direction
overrides, newlines, zero-width marks, a kilobyte long, markup) and the filter,
1000 outputs with the one in use first, 50 VPNs and 100 Bluetooth devices, a player skipping and pausing faster than the card draws,
NetworkManager restarting while a password is typed, the centre's monitor
unplugged under an open menu, every pill hammered faster than its service
answers, a 1024x600 screen at 1.2 with a password row scrolled into view, and
a 4K monitor at scale 2 with the shell at 1.2. `interactions.sh`
holds fixes that had no case: a long popup's two clicks, the wheel over a
level past 100 %, a picked clip's scope, every panel on a 1024x600 screen
and Power Off's second press. Behaviour that broke once gets a case; check that
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
