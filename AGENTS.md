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
| `palettes` | `attrsOf (attrsOf str)` | `adwaita_dark` (libadwaita 1.9's dark style under its own names: every named colour, translucent ones as CSS `#rrggbbaa`, the accent swatches and the GNOME palette, plus ghostty's terminal colours; quickshell, hyprland, hyprlock, wezterm, tmux). |
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
| `tmux/` | homeManager | `tmux` | tmux on built-ins, themed from `palettes.adwaita_dark`: a bare `tmux` attaching to the session `main` (a package wrapper), a vim keymap on `C-b` (prefix table reset, no arrows), `choose-tree` for jumping, a copy-mode selection on the clipboard (OSC 52) as it changes, `prefix e` opening the scrollback in nvim (only with `programs.neovim`), framed pane titles, rounded popups/menus, bells from background windows marked (pi rings one) and `prefix o` to jump; resurrect + continuum loaded last by `run-shell`, since home-manager's `plugins` load before `extraConfig`; a post-save-layout hook saves each pi pane as `pi --session <its @pi_session>`, so panes sharing a directory each get their own session back |
| `users.nix` | nixos, homeManager | `users` | primary user, groups, hashed password, zsh (no global compinit; oh-my-zsh runs it) + starship, root locked |
| `wezterm.nix` | homeManager | `wezterm` | wezterm with an "Adwaita Dark" scheme from `palettes.adwaita_dark`, Hack font, notifications only while its window is unfocused |
| `xdg.nix` | homeManager | `xdg-user-dirs` | XDG user dirs (created; projects = HM default `~/Projects`) |
| `zsh.nix` | homeManager | `zsh` | oh-my-zsh, autosuggestions, syntax highlight, 100k history, `programs.fzf` keybindings (Ctrl-R/Ctrl-T/Alt-C) |

Notes on specific features:

- **`hyprland/`** is split across `default.nix` (nixos + HM base),
  `bindings.nix`, `rules.nix`, `hypridle.nix`,
  `hyprlock.nix`, `hyprmoncfg.nix`, `plugins.nix`, `quickshell.nix`, plus `assets/`, `scripts/`
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
    center from the bar's clock) are a [Quickshell](https://quickshell.org)
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
    calendar and notification ages), `WorkspaceOwners` (hyprsplit's numbering,
    for the bar and the window switcher), `Command` (a process whose output
    arrives as `done`, and whose failure, a program that cannot start or
    crashes included, becomes a notification that closes
    the panel open as it started, or only a log line while `quiet`, a load nobody waits
    on), `Overlay` (the full-screen layer a panel lives in, closing it on a
    click anywhere but its `card`, and leaving `Panels` when Hyprland closes
    it with its monitor), `Card` (the surface of panels and
    popups: libadwaita's window background, outline and shadow; Escape
    closes the panel it is in), `Button` (libadwaita's button, `flat` or
    not, with an optional expander arrow; `ExpandButton` and `CloseButton` are
    its round flat 24 px forms), `Glyph` (a Material Symbols path at a size),
    and `Panels`, the one open panel by name, with
    the IPC target `panels` (`qs ipc -c shell call panels open|close|toggle
    <name>`; `apps`, `clipboard`, `monitors`, `windows`, `nixpkgs`, `center`, `shortcuts`, `power`): opening any panel (a
    launcher mode, the notification center, a tray menu) closes the others, and
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
    - `Theme` is libadwaita's dark style 1:1: its named colours
      (`palettes.adwaita_dark`, `view_bg_color` surfaces), hover/selection/
      border as the foreground at libadwaita's alphas over any surface, its
      type scale as `font` values (`Theme.body`, `heading`, `caption`,
      `title4`, …; Adwaita Sans at GTK's 11pt) and its radii (button 9, card
      12, window 15). Panel widths follow GNOME Shell's, in em of the body
      font (`Theme.em`): 30em popups (GNOME's are 34em), its calendar
      days. `shell.qml` sets `QT_SCALE_FACTOR=1.2` (an `Env`
      pragma), Qt's own high-DPI scaling, so it all draws 1.2× and sharp;
      apps and links the shell opens get the variable removed.
    - The shell is written like any Hyprland rice, so it works on other
      setups: the QML runs its tools by name from PATH (`cliphist`, `wl-copy`,
      `pw-play`, `notify-send`, `xdg-open`, `systemd-run`, `hyprmoncfg`,
      `wezterm`, `curl`, `nixpkgs-index`, `nixpkgs-run`) rather than store paths, an exception to the rule above;
      `quickshell.nix` installs the ones no other feature does. The only Nix
      in the QML is `palettes.adwaita_dark` as the `Colors` singleton (translucent
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
        mid-hotplug say, only logs while there is a status to show.
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
        5 s. A failed build notifies with nix's last lines; what it builds
        stays in the store until GC.
      - `windows`: every window from wlr-foreign-toplevel
        (`ToplevelManager`), so it works on any compositor, the focused one
        last. On Hyprland the rest come in focus order (a `refreshToplevels`
        as it opens), each with its monitor and workspace as the bar numbers
        it, and Enter dispatches `hl.dsp.focus({ window = "address:0x…" })`;
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
      `BarWindow` per screen), sized and lettered like the waybar it replaced
      (Adwaita Sans at 16 px, on GNOME Shell's panel black): the NixOS logo
      (`nixos.svg`, opening the power menu), the monitor's workspaces, the
      clock (a flat round button with a pointing hand, as GNOME's panel draws its date: shaded on
      hover and while the center it opens is open), the battery and the tray. Quickshell keeps Hyprland's state by
      events but only refreshes monitors as one comes or goes and ignores
      renames, so `Bar.qml` refreshes monitors and workspaces on those, and
      once more 300 ms after the last, since Quickshell drops a refresh while
      one is under way and a hotplug comes as a burst.
      - Workspaces: each bar shows its monitor's own `1 … n` (monitor id × n
        + 1 onwards, as hyprsplit numbers them), then any other workspace on
        it, named after the monitor that owns it (`DP2-1`), and named ones by
        name; specials are left out. `WorkspaceOwners` remembers the connector
        last seen with each monitor id in the state dir, so a workspace left
        behind by an unplugged monitor still carries its name (the bare id if
        never seen). Bold and centred on its ink, dim while empty, a pill while shown, outlined when
        foreign, red when urgent; pressing one focuses it by id wherever it
        is.
      - The tray is bare icons without hover states, hiding passive items;
        left click activates (or opens the menu of a menu-only item), middle is the secondary action, right opens
        the menu: `TrayMenu`, libadwaita's popover menu drawn from
        `QsMenuOpener` with its corner at the pointer (leftwards where it would
        run off the screen), on an overlay (a `Panels` panel per screen) whose
        input region is only its cards (`Region.regions`), stray separators
        dropped. Check and radio items get libadwaita's check buttons, and a
        card that has any (or any icon) keeps their column on every row, so the
        labels line up. Submenus cascade as GTK's do: a card each, beside the row that
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
      - The battery (`Power`) is UPower's display device, shown only when
        UPower is running and it is a laptop battery, so only thonkpad
        enables UPower; `qs ipc -c shell call bar fakeBattery 15 false` shows a
        made-up one anywhere, `realBattery` drops it.
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
      focused when each arrived (the first one's once it is gone), below the bar, sliding in and out (the
      window stays mapped with an empty input region, so the last one does
      too); the app's timeout or 8 s, critical never, hovering holds it;
      a click on one with more to show (a cut-off title or body) expands and
      collapses it, as its arrow does, and otherwise runs the default action,
      or puts the popup away when there is none; an action or a link puts it
      away too (a resident notification stays open, as GNOME's banners do);
      right click, a swipe or a fast flick towards the edge slides it away and
      dismisses it; more than three actions fold into a "More" dropdown.
      Popups have no close cross; the center's notifications do.
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
      whose links open, with a pointing hand over them), `NotificationAge` and
      `SwipeArea` (which moves its card itself, and slides it away carrying on
      from the drag) are shared with the center. Do not disturb is saved in
      Quickshell's state dir and lets only critical notifications pop up.
      Sounds are elementary OS's (Unlicense) in `sounds/`, played with
      `pw-play` (Quickshell has no QtMultimedia) when a popup shows; low
      urgency is silent whatever it asks, and `suppress-sound`, `sound-file`
      and `sound-name` (looked up in the freedesktop sound theme) are
      honoured, so the server advertises `sound`. Scripts use
      `qs ipc -c shell call notifications
      <toggleDnd|setDnd|dnd|count|clear|hidePopups>`. History lives in memory;
      a restart of the service empties it, by design.
    - `center/` is the notification center (`qs ipc -c shell call panels
      toggle center`), GNOME's layout, dropping down from the middle of the bar with
      a short fade and slide: notifications on the left (40em, wider than
      GNOME's 29em, which read long and narrow), a Do Not Disturb
      switch and Clear (which also closes it) below, and `Calendar.qml` on
      the right (locale's first weekday, ISO week numbers, arrows or wheel for
      months, the date returns to today) with the weather under it, left out
      where the screen is too short for both. Opening it puts the popups away. Notifications are grouped
      per app the way end-4's dots do (`NotificationGroup`,
      `NotificationItem`): one card with the app's icon, name and count, and a
      flat arrow button and, under the pointer, a close cross, over its two newest notifications a line each with
      their own age (a lone notification has its age in the header, and the
      arrow only when expanding shows more: buttons, progress, or a cut-off
      title or body); expanded,
      each gets an inset card with its image, whole body, actions and a close
      cross under the pointer, and a lone one's title wraps in full. A click on
      a group with more to show expands and collapses it; on a lone one with
      nothing more it runs the default action; in an expanded group of several
      a notification's click runs its own. Right click or a swipe dismisses the group,
      or once expanded, one notification. The list grows with its
      notifications up to the screen's height, then scrolls. Mouse only, and unlike the launcher
      it is smooth: the list drags and flicks with Qt's overshoot, a wheel
      notch glides 120 px (Qt's own moves the 15 px Wayland reports), and
      groups animate their height. Escape or a click
      outside closes it, and its `quickshell:center` layer rule dims behind
      it. The popups and the center cast libadwaita's window shadow
      (`common/Shadow.qml`, Qt's `RectangularShadow`), and their expand
      toggles use libadwaita's arrow (`common/ExpanderArrow.qml`, Adwaita's
      `pan-down-symbolic` as a `Shape`).
  - hyprlock talks to fprintd itself (`auth:fingerprint`, on when
    `services.fprintd` is), so the NixOS half turns `fprintAuth` off for
    hyprlock's PAM service.
  - Every lock (idle, sleep, the power menu's Lock) goes through
    `loginctl lock-session`, so hypridle's `lock_cmd`, which never starts a
    second hyprlock, is the only thing that runs it.
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
`qt` are homeManager.

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
- `checks.<system>.notification-markup` (Linux) — `qmltestrunner` over
  `tests/tst_markup.qml`: what the notification body filter
  (`notifications/markup.js`) keeps, drops and escapes.

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
qst click                      # left, where the pointer is; or `qst click right 1896 21`
qst drag 1631 112 320 0 250    # press at x y, move dx dy over ms, release: a swipe
qst wheel 3                    # notches, positive down
qst layers                     # the layer surfaces up: which panels are open, on which monitor
qst shot apps                  # numbered PNG in $QS_TEST_DIR/shots, path printed
qst shot crop "360,330 600x260"
qst shot dp2 DP-2              # one monitor
qst monitor add DP-2 2560x1440 1.25   # hotplug; `monitor remove DP-2` unplugs
qst output 2560x1440 1.5       # the first monitor's mode
qst key super+Return           # real windows, for workspaces and the window switcher
qst tray                       # a tray item with nested submenus (tests/tray.qml); `qst tray log` shows what it was told
qst x notify-send -a Discord loft01 hello   # anything else, inside the session (hyprctl talks to the test Hyprland)
qst sync                       # copy edited QML in, restart qs, print its warnings; non-zero if it fails to load
qst problems                   # warnings and errors, less the expected ones
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
`$QS_TEST_DIR/cfg/hyprmoncfg/profiles`.

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
- Animation: background `qst x grim -s 0.25 <file>` shots about 35 ms apart, then
  `md5sum` to see which frames settled.
- Never `pgrep -f <pattern> | xargs kill`: the pattern is in the calling
  shell's own command line. `qst down` finds the session's processes by its
  runtime dir and D-Bus address in their environment.
- Quickshell keys its state and cache dirs by config path, so the test
  shell's are its own; `qst down` deletes only those.

## Sharp edges

- **pi's `settings.json` is a read-only store symlink.** Anything pi would
  normally save itself (`theme`, `defaultProvider`, `defaultModel`,
  `defaultTools`, `packages`, `defaultProjectTrust`) fails to write and reverts
  on restart; set those through the home-manager option `piAgent.settings`
  instead. pi's own files (`auth.json`, `sessions/`, `npm/`) are unaffected.
- **pi themes cannot paint the screen background.** The theme format has no
  global background token; only the per-box `*Bg` tokens exist. The backdrop is
  the terminal's, i.e. wezterm's Adwaita Dark background.
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
