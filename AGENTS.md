# AGENTS.md

Technical reference for agents. User-facing quickstart: [README.md](./README.md).
Shell design standard: [`quickshell/STYLE.md`](./modules/features/hyprland/quickshell/STYLE.md); a new widget starts at its "Start here" table.

## What this is

One flake holding all of `leier`'s NixOS and home-manager configurations, in
the [dendritic pattern](https://github.com/mightyiam/dendritic): one top-level
`lib.evalModules`, and every module of every class is a value of it. No
flake-parts; the substrate is hand-rolled in `flake.nix`, `import-tree.nix` and
`modules/flake/`.

## Non-negotiables

- **A file is a feature.** One `.nix` under `modules/features/` describes every
  class it touches (`nixos`, `homeManager`). No side files per class.
- **Share constants through the top-level configuration, never `specialArgs`.**
  Data several features read is a declared top-level option (`identity`,
  `palettes`, `hyprland.workspaces`), read as `root.config.<option>`.
- **Anything a host or importer sets is an option of the feature's class
  module.** Top-level values are global and baked into exported aspects, so
  per-host knobs live in the aspect (`programs.pi-coding-agent.settings`,
  `neovim.outOfStorePath`, `hyprmoncfg.profiles`, `quickshell.scale`), set from
  the host's home aspect or the importer.
- **Install through the module when one exists** (`programs.<x>.enable`,
  `services.<x>`), so others can read `config.programs.<x>.package`. Skip
  modules that take over mutable app state (firefox profiles, discord/obsidian
  settings).
- **A feature delivers everything it relies on.** Any aspect imported alone
  works: tools it calls are on its own PATH (wrapper or `extraPackages`),
  commands are store paths (`lib.getExe config.programs.<x>.package`), fonts it
  names it installs, paths come from `config` (`config.xdg.configHome`), not
  env vars another feature exports. Only the base OS (coreutils, curl, tar,
  systemd) is assumed.
- **`imports` in a host is the whole machine.** Host builders inject only
  hostname, platform and a `stateVersion` default.
- **No AI credit.** No `Co-Authored-By`, no "Generated with", in commits, PRs or
  files, whatever a tool's default says.
- **No comment is the best comment.** If needed: one line, why, never what.
- No flake-parts dependency, no `specialArgs` plumbing.
- **Never hardcode the username.** Read `config.identity.username`.

## Repo map

```
flake.nix                 entry point: evalModules { class = "flake"; ... }
import-tree.nix           dir -> module that imports every .nix beneath it
README.md, AGENTS.md      user doc, this file
TODO.md                   plain bullets, no headings: upstream candidates, leads, what is left open

modules/flake/            the substrate
modules/features/         one flat file per feature (+ hyprland/, moonshine/, neovim/, pi-agent/, tmux/)
modules/profiles/         base.nix, workstation.nix
modules/theme/            palette, fonts, gtk, qt, cursor
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

Every file is a module of this one configuration, so each may read `config`,
`lib` and `inputs` at the top level.

Inputs: `nixpkgs` (26.05), `nixpkgs-unstable`, `home-manager` (26.05),
`home-manager-unstable` (only for `programs.pi-coding-agent` until 26.11),
`disko`, `nix-index-database`, `hyprland` (pinned tag; dev-only
`pre-commit-hooks` pruned with `follows = ""`), `hyprsplit` (`nixpkgs` follows
`hyprland/nixpkgs`), `moonshine` (upstream `main`; `nixpkgs` follows ours, only
its sources used).

### `import-tree.nix`

A directory becomes a module importing every `.nix` beneath it. Names starting
with `.` or `_` are skipped: `_` is the escape hatch for non-module Nix.

### Classes and tagging — `modules/flake/outputs.nix`

`flake.modules.<class>.<aspect>` is the registry, typed
`lazyAttrsOf (lazyAttrsOf deferredModule)`: files assigning the same aspect
merge (how `features/hyprland/*.nix` build one `homeManager.hyprland`). `apply`
wraps each module:

```nix
{ ... }: {
  key = "flake.modules.${class}.${name}";
  _class = class;                              # nixos | homeManager
  _file = "flake.modules.${class}.${name}";
  imports = [ module ];
}
```

`_class` turns a wrong-class import into a type error, `_file` gives readable
error locations, `key` applies an aspect imported along two paths once.

The registry is exported as the flake output `modules` (Nix warns `unknown
flake output 'modules'`; intended), so `inputs.nixdots.modules.homeManager.<aspect>`
works elsewhere. Values an aspect reads from `root.config` are this flake's; an
importer changes them through the aspect's options or `lib.mkForce`.

### Top-level options

| Option | Type | Notes |
| --- | --- | --- |
| `identity` | `{ username, fullName, email }` | Primary user; read by `users`, `git`, `home-manager`, profiles |
| `palettes` | `attrsOf (attrsOf str)` | `adwaita_darker`: libadwaita 1.10's dark named colours (translucent ones as CSS `#rrggbbaa`), accents and GNOME palette, GNOME Shell 51's opaque surfaces as `shell_*`, ghostty's "Adwaita Dark" terminal colours. Opaque surfaces are upstream's less `depth` (28 per channel), after [Darkwaita](https://github.com/varunbpatil/Darkwaita): `view_bg_color` `#010104`, Shell's popover `#1a1a1e`; the terminal background half as much (`#0f0f12`). Accents, text, translucent and ANSI colours unchanged. Read by quickshell, hyprland, hyprlock, hyprtoolkit, GTK, wezterm, tmux |
| `hyprland.workspaces` | positive int | Workspaces per monitor; hyprsplit, binds, the bar |
| `nixosHosts.<name>` | submodule `{ system }` | Drives `flake.nixosConfigurations` |
| `systems` | `listOf str` | Default `[ ]`; `per-system.nix` sets `[ "x86_64-linux" "aarch64-darwin" ]` |
| `perSystem` | `deferredModule` | Evaluated once per `systems` entry |

Flake outputs: `modules`, `nixosConfigurations`, `formatter`, `checks`,
`devShells`, `packages`.

### `perSystem` — `modules/flake/per-system.nix`

Per system, a nested `evalModules` of class `"perSystem"` with
`{ inputs, system, root }` (`root` = top-level config), `pkgs` with
`allowUnfree`, and options `packages`, `checks`, `devShells`, `formatter`,
collected into system-keyed outputs. Any module may define `perSystem`;
definitions merge. Don't redeclare `systems`.

### Host builders

- **`nixos-hosts.nix`**: `nixosHosts.<name>` → `lib.nixosSystem`. `mkDefault`s:
  `networking.hostId` (first 8 chars of `sha256(hostname)`, so a rename changes
  it), `networking.hostName`, `nixpkgs.hostPlatform`, `system.stateVersion` =
  `lib.trivial.release` (don't bump without knowing the migrations). Imports
  `flake.modules.nixos."nixosConfigurations/<name>"`.
- **`offline-installer.nix`**: per host, `nixosConfigurations.offlineInstaller-<host>`:
  an install CD carrying the host's `toplevel` and disko `destroyFormatMount`,
  substituters and channels off, root autologin, keymap/locale/timezone from the
  host, and `offline-installer` (disko asks `yes` before wiping, then
  `nixos-install --no-root-passwd --no-channel-copy`).

Aspect names are load-bearing: `"nixosConfigurations/<host>"` is the host's
NixOS aspect, `"nixosConfigurations/<host>/home"` its home-manager aspect, which
`home-manager.nix` imports on the host whose `networking.hostName` matches.

## Features (`modules/features/`)

Each file exports `flake.modules.<class>.<aspect>`; files needing shared values
take `root@{ inputs, lib, ... }:` and read `root.config.<option>`.

| Feature | Classes | Aspect(s) | What it does |
| --- | --- | --- | --- |
| `bluetooth.nix` | HM | `bluetooth` | `bluetui` when the host has `hardware.bluetooth` (`osConfig`); the control centre's Bluetooth Settings |
| `boot.nix` | nixos | `boot`, `systemd-boot` | GRUB on EFI (themed); `systemd-boot` `mkForce`s GRUB off, conflicts by design, unused |
| `desktop-apps.nix` | HM | `desktop-apps` | GUI apps every workstation gets; Loupe and Celluloid the default image viewer and video player through `~/.local/share/applications/mimeapps.list` (below the mutable `~/.config/mimeapps.list`, which apps write and "Open With" overrides); Celluloid on an mpv.conf (`hwdec=auto-safe`, its default is software; `profile=fast`) and graphics offload via dconf |
| `display-manager.nix` | nixos | `display-manager` | ly |
| `doas.nix` | nixos | `doas` | doas replaces sudo (`doas-sudo-shim`); wheel `noPass`, no `keepenv`, passes only `LANG`, `NIX_PATH`, `SUDO_*` |
| `documentation.nix` | nixos | `documentation` | NixOS manpages off |
| `gaming.nix` | nixos | `gaming` | Steam + proton-ge |
| `git.nix` | nixos, HM | `git` | git, identity from `identity` |
| `home-manager.nix` | nixos | `home-manager` | HM for `identity.username`, `useGlobalPkgs`/`useUserPackages`, `backupFileExtension = "hm-bak"`; pulls `nixosConfigurations/<host>/home` |
| `homelab.nix` | HM | `homelab` | just, helm, virtctl, kubelogin, `programs.gh`, ssh `loft01` forwarding 6443; both homes import it |
| `hyprland/` | nixos, HM | `hyprland` (+ `hyprland.workspaces`, HM `hyprmoncfg.profiles`, `quickshell.scale`) | below |
| `journald.nix` | nixos | `journald` | 90-day retention |
| `locale.nix` | nixos | `locale` | `no`/`nodeadkeys`, `en_DK.UTF-8`, Europe/Oslo, timesyncd; hyprland reads xkb via `osConfig` |
| `moonshine/` | nixos | `moonshine` | below |
| `neovim/` | nixos, HM | `neovim` (+ HM `neovim.outOfStorePath`) | below |
| `network.nix` | nixos | `network` | resolved with DNS-over-TLS to Quad9, no plaintext fallback; NetworkManager (DHCP DNS ignored, stable MACs, wifi powersave off, no auto wired profile); nftables; no ping; rp-filter `loose` (WireGuard full tunnels) |
| `nix.nix` | nixos | `nix` | GC, `auto-optimise-store`, flakes, cache, no global registry; `nixpkgs` registry/`NIX_PATH` from `nixpkgs.flake.source` |
| `nix-index.nix` | HM | `nix-index` | small prebuilt DB + wrapped comma |
| `nixpkgs.nix` | nixos | `nixpkgs`, `unstable-nixpkgs` | `allowUnfree`; overlay `pkgs.unstable`. Prefer default `pkgs` unless a package needs unstable |
| `packages.nix` | nixos | `packages` | jq, fzf, fastfetch, tree, kubectl |
| `pi-agent/` | HM | `pi-agent` (imports `programs.pi-coding-agent`) | below |
| `plymouth.nix` | nixos | `plymouth` | plymouth + quiet boot |
| `podman.nix` | nixos | `podman` | docker compat, DNS on `podman0` |
| `sound.nix` | nixos | `sound` | pipewire + rtkit |
| `tmux/` | HM | `tmux` | below |
| `users.nix` | nixos, HM | `users` | user, groups, hashed password, zsh + starship (oh-my-zsh runs compinit), root locked |
| `wezterm.nix` | HM | `wezterm` | "Adwaita Darker" from the palette, Hack, notifications only while unfocused |
| `xdg.nix` | HM | `xdg-user-dirs` | XDG user dirs, created |
| `zsh.nix` | HM | `zsh` | oh-my-zsh, autosuggestions, highlighting, 100k history, fzf keys |

### `moonshine/`

[Moonshine](https://github.com/hgaiser/moonshine) from its flake (upstream
`main`), via its NixOS module (which disables nixpkgs'). The package is built
against our nixpkgs, since its implicit Vulkan layer loads into every Vulkan
app (ferriscope's source passed from moonshine's own input). Each Moonlight
stream gets its own headless compositor at the client's mode. One app: Steam
`-gamepadui` in gamescope, `DISABLE_FERRISCOPE_WSI`, `--xwayland-count 2` (on
one Xwayland a game loses X focus to the overlay and never comes back), Deck UI
(Big Picture `-tenfoot` froze the stream). User joins `input` (virtual pads) and
`moonshine` (sleep-inhibit polkit rule). A desktop Steam is shut down first
(single instance). Logs: `journalctl --user -u moonshine-session`. The host sets
`services.moonshine.openFirewall` and `uid` (allocated, not declared;
`hosts/desktop/streaming.nix`).

### `tmux/`

Built-ins only, themed from the palette. Bare `tmux` attaches to `main` (a
wrapper). Vim keys on `C-b` (prefix table reset, no arrows), `choose-tree` to
jump, copy-mode selection to the clipboard via OSC 52 (plus `pbcopy` on
macOS, as Terminal.app ignores OSC 52), `prefix e` opens
scrollback in nvim (only with `programs.neovim`), framed pane titles, rounded
popups, bells from background windows marked (pi rings one), `prefix o` jumps
to one. resurrect + continuum load last via `run-shell` (HM `plugins` load
before `extraConfig`). A post-save-layout hook saves each pi pane as
`pi --session <@pi_session>`, so panes sharing a directory keep their own
session.

### `neovim/`

In-tree Lua config. `xdg.configFile."nvim".source` is the module dir, or
`neovim.outOfStorePath` (a checkout) for live editing. git, LSP servers,
formatters, `gcc`, `tree-sitter`, `fzf`, `wl-clipboard` (Linux) are
`extraPackages` (nvim's PATH only); ripgrep and fd come from `programs.ripgrep`
/ `programs.fd`. LSP overrides in `after/lsp/`. HM's own `init.lua` is
sideloaded (`sideloadInitLua`). Plugins: `vim.pack` (0.12+), pinned by the
committed `nvim-pack-lock.json`:

- writable checkout: `vim.pack` uses it in place;
- read-only store: `init.lua` points `vim.pack` at a copy in
  `~/.local/share/nvim/nvim-pack-config/`, reseeding it and running
  `vim.pack.update(nil, { target = "lockfile", force = true })` when the
  committed lockfile changes.
- To update from a store install: `:lua vim.pack.update()`, copy the lockfile
  from that dir into `modules/features/neovim/`, commit, `:TSUpdate`.

### `pi-agent/`

Configures HM's `programs.pi-coding-agent` (imported from
`inputs.home-manager-unstable` with its `modules/lib` overlay until
`release-26.11` ships it) with `pi-coding-agent` from `inputs.nixpkgs-unstable`
directly (the mac lacks `pkgs.unstable`). `extraPackages` suffixes `git` and
`nodejs` so a project shell's win (nixpkgs' wrapper already prefixes `rg` and
`fd`). Writes into `config.programs.pi-coding-agent.configDir` (`~/.pi/agent` by
default): `settings.json` (with `mutableSettings = true`, so activation merges
declared settings in place while pi can still write its own keys like
`defaultProjectTrust`; both hosts pin provider, model, thinking level `max`;
Copilot's Claude Opus 5.5 starts at `high` through `modelThinkingLevels`),
`models.json` (DeepSeek V4.1 Flash at its agentic evals' `top_p` 0.95,
temperature 1), `APPEND_SYSTEM.md` (`appendSystem`), the `commit-style` skill,
a `bell` extension (BEL on finish or prompt) and `tmux-session` (session file in
pane option `@pi_session`). pi packages are pinned in `settings.packages`,
installed by pi with nixpkgs' `npm` into `~/.pi/agent/npm`.

Sharp edges: with `mutableSettings = true`, removing a declared key from
`settings` does not delete it from the existing `settings.json`; delete it by
hand. pi themes cannot paint the background (no global token); it is wezterm's.

### `hyprland/`

Files: `default.nix` (nixos + HM base), `bindings.nix`, `rules.nix`,
`hypridle.nix`, `hyprlock.nix`, `hyprmoncfg.nix`, `hyprtoolkit.nix`,
`plugins.nix`, `quickshell.nix`, `assets/`, `scripts/`, `tests/`,
`quickshell/`. The HM half reads `osConfig` (compositor package, xkb,
fprintd, NetworkManager), so it needs the NixOS half.

- **Lua settings API** of the pinned Hyprland: binds and events via
  `lib.generators.mkLuaInline` and `_args`. `bindings.nix`' `mkBind` gives every
  bind a `desc` (shown by `hyprctl binds`, so SUPER+?) and generates workspace,
  direction and XF86 binds. Binds reference configured packages
  (`config.programs.wezterm.package`), not `pkgs.*`.
- **hyprsplit** (`plugins.nix`): declares `hyprland.workspaces`, loads the Lua
  library as `hs` (`hs.dsp.focus`, `hs.dsp.window.move`). Monitor *k*'s
  workspaces are `k*n+1 … (k+1)*n`, shown as `1 … n`; *k* is the monitor id,
  which Hyprland reuses per connector name.
- **Session daemons** are HM user services on `hyprland-session.target` via
  `wayland.systemd.target`, which Hyprland ≥ 0.57 starts itself (HM's bounce
  off, environment import only): quickshell, cliphist (wiped at start), hyprmoncfgd,
  hypridle, hyprpolkitagent, hyprpaper (a config reload restarts it),
  hyprsunset (`--identity`, untinted; the control centre's night light). No
  nm-applet. A service for another compositor needs its own target.
- **Monitors**: [hyprmoncfg](https://github.com/crmne/hyprmoncfg) (unstable,
  built against the pinned Hyprland). Profiles are declared only
  (`hyprmoncfg.profiles`, outputs by EDID, workspace planning off) into one
  read-only store dir, so the TUI cannot save. SUPER+P applies one through the
  launcher's `monitors` mode. A catch-all `monitor` rule (preferred, auto, 1)
  covers the rest. `hyprland.lua` is read-only, so the module appends
  hyprmoncfg's `dofile` with `lib.mkAfter`; it must stay the last line.
- **hyprtoolkit** (`hyprtoolkit.nix`, for hyprpolkitagent ≥ 0.2 and
  hyprland-guiutils): libadwaita dark on the darker palette, fg at 10/15 %
  made opaque, Adwaita Sans, Papirus-Dark, radii 9/12, accent `blue_5`
  (hyprtoolkit writes dark text on an accent lighter than OkLab 0.5).
- **hyprlock**: talks to fprintd itself (`auth:fingerprint` when
  `services.fprintd`), so the NixOS half turns PAM `fprintAuth` off for it.
  Background: each screen's screenshot blurred (3×8) at brightness 0.6,
  `contrast = 1`; `dark_5` without screencopy. Clock Adwaita Sans Bold 64 pt,
  date 24 pt, field at −100, fingerprint prompt at −170. `fadeIn` 600 ms
  crossfades from the screenshot; `fadeOut` off (it fades back to the
  screenshot, then cuts).
- **Locking**: everything goes through `loginctl lock-session`; hypridle's
  `lock_cmd` (`lock`, in `hypridle.nix`) is the only thing that runs hyprlock,
  never twice. Under an idle dim it asks the shell its darkness (`idle hold`,
  which also freezes the dim) and starts hyprlock on a copy of its config
  (`$XDG_RUNTIME_DIR`) with brightness 0.6 ÷ (1 − darkness), so every lock ends
  on the same picture. `on_lock_cmd` (`idle locked`) drops the dim and blocks
  new ones; `on_unlock_cmd` and `lock` exiting (`idle unlocked`) clear all.
  hyprlock dying by a signal is started again, three times at most
  (`allow_session_lock_restore`), so a crash never needs a TTY.
- **Idle dim** (`quickshell/idle/`, layer `quickshell:idle`): 10 s before the
  lock hypridle runs `qs ipc -c shell call idle fade 10 0.4` (0.4 black for
  hyprlock's 0.6), its resume `cancel`, so input brings the screens back. A
  fingerprint unlock (no input) clears it through `on_unlock_cmd`. hypridle is
  the one clock and input watcher; without a shell the lock just comes. Sleep
  and the power menu lock at once.
- **hypridle is `pkgs.unstable.hypridle`** (0.1.8): 0.1.7's single inhibit counter
  loses logind's idle inhibitor to a stray ScreenSaver `UnInhibit` and an app
  disconnect, so Caffeine stopped keeping the lock off. Drop the pin when
  nixpkgs moves to 26.11.
- **Screenshots**: one `writeShellApplication` (`scripts/freeze-region.sh`,
  `copy|save`), ending in a transient, silent notification from "Screenshot"
  with the shot as picture (`file://`) and `accessories-screenshot` badge
  (`-n`). Copies share stack tag `screenshot` (picture in
  `$XDG_RUNTIME_DIR/screenshots` until the next); saves are untagged with Open
  and Show in Folder. Escape in slurp sends nothing; a failure is a critical
  "Screenshot Failed".

## The Quickshell shell (`hyprland/quickshell/`)

[Quickshell](https://quickshell.org) 0.3.2 from `pkgs.unstable` (0.3.1 fixed
crashes on freed objects in a `ScriptModel`). `quickshell.nix` runs it as
`quickshell.service`: restarted when the shell changes (`X-Restart-Triggers`),
1 s after a crash, no start limit (hotplug bursts), `MemoryMax=2G` without swap
(it sits near 500 MiB). Quickshell's own guard also restarts a crashed
instance in place and logs "Quickshell has crashed under pid N".

Components: `bar/`, `center/`, `controls/`, `launcher/`, `notifications/`,
`osd/`, `power/`, `shortcuts/`, `tooltip/`, `weather/`, `idle/`; `shell.qml`
only instantiates them. `common/` holds what several share: the STYLE.md
pieces, `Theme` (only it reads `Colors`), `Panels`, `Overlay`, `Popover`,
`ClickAway`, `Screens`, `Time`, `StateFile`, `Command`, `Detached`, `WheelSteps`,
`WorkspaceOwners`, `Tooltips`, `Machine` (os-release's `LOGO=` through the
icon theme, hostname, uptime).

### Wiring

- **`Panels`**: the one open panel by name; opening one closes the others;
  nothing opens with no monitor on (it would land on `FALLBACK` holding the
  keyboard). IPC `panels open|close|toggle <name>`: `apps`, `clipboard`,
  `monitors`, `windows`, `nixpkgs`, `center`, `shortcuts`, `power`, `gallery` (qs-test
  only), per screen `controls:DP-1`, `tray-menu:DP-1`.
- **`Overlay`**: the full-screen layer a panel lives in; a click off its `card`
  or a window elsewhere taking the keyboard closes it. Exclusive keyboard only
  until it has it, or a window clicked on another monitor never got it.
  `Popover` (the control centre, the center) is one that fades in and out,
  letting clicks and the keyboard go as it closes, then says `hidden`.
- **`ClickAway`**: a layer under the windows on every screen, taking input only
  while a panel is open, so bare desktop closes it.
- **`Screens`**: screens less Hyprland's `FALLBACK`, and the focused one.
- **`Command`**: a process whose failure (even to start) becomes a
  notification, or a log line while `quiet`. **`Detached`**: one
  `systemd-run --user --scope` per app, since a service restart kills its
  cgroup.
- **Nix in the QML** is only the `qs.nix` module in the store copy: `Colors`
  (the palette, translucent colours as Qt `#aarrggbb`), `Hyprsplit.workspaces`
  and `Symbols` (MDI 7.4 from `@mdi/svg`, `scripts/symbols.mjs` over
  `scripts/symbols.tsv`). So the shell runs from the built copy
  (`programs.quickshell.configs.shell`), not the checkout.
- **Tools by name from PATH** (`cliphist`, `wl-copy`, `pw-play`, `notify-send`,
  `xdg-open`, `systemd-run`, `hyprmoncfg`, `wezterm`, `curl`, `nixpkgs-index`,
  `nixpkgs-run`, `hyprctl`, `systemctl`, `wpctl`, `camera-users`,
  `backlight-watch`, `nmcli`, `nm-connection-editor`, `brightnessctl`,
  `bluetui`, `pwvucontrol`), so it works as any rice: an exception to store paths;
  `quickshell.nix` installs those no other feature does.
- **Scale**: designed at scale 1 (1920x1080). Hyprland's per-monitor scale
  handles dense screens; HM `quickshell.scale` (default 1, the desktop 1.2)
  sets `QT_SCALE_FACTOR` for the shell alone, removed for what it launches.
- **A new component**: a directory with a `Scope`, a line in `shell.qml`, an
  `IpcHandler` if scripts drive more than its panel, and for a keybind a
  `GlobalShortcut` bound in `quickshell.nix` with
  `hl.dsp.global("quickshell:<name>")` (no `qs ipc` process per press).

### QML conventions

- Comments: none by default, no headers, one line why. What a component does
  lives here, not in QML.
- Colours, fonts, radii, spacing, durations from `Theme`. A size one component
  owns stays in it.
- Shared pieces go to `common/` at about three uses; a widget used in one file
  is an inline `component`, unless the file does several jobs.
- Bindings over imperative code; handlers only react. Transient windows are
  created as they open (`LazyLoader`, `Variants` keyed by what they show), so
  each open starts fresh.
- Every panel through `Panels`; saved state through `StateFile`.
- Check behaviour against source (Quickshell, Qt, Hyprland), and test it in
  qs-test before it lands.
- An inline component or delegate sees the file's ids before its own
  properties: read those through its own id (`list.results`, `row.heading`).
- Cursors: a `MouseArea` always sets one, an arrow unless told; Qt takes the
  topmost. One laid over others (for the wheel) or beside a parent's
  `HoverHandler` needs `cursorShape: undefined`. Hand where a click acts,
  arrow where it does nothing or only dismisses, closed hand while dragging. A
  disabled `MouseArea` still sets its cursor, so name both. Tray icons keep the
  arrow (few act on a left click). `qt.quick.hover.cursor` logging names the
  winner.
- Hover: Qt 6 hovers one leaf item and its ancestors, never the siblings under
  it, and a press marks a `MouseArea` hovered outside that tracking, so nothing
  clears it. Never lay a hover-taking item over a `MouseArea` whose
  `containsMouse` you read: `TooltipArea` puts its `HoverHandler` on its owner
  for this.

### Gotchas, each found the hard way

- A `PopupWindow` lands off by its monitor's x × (`QT_SCALE_FACTOR` − 1) except
  at x 0: anything floating is its own layer (`PanelWindow`/`Overlay`) in that
  screen's coordinates.
- Qt's JS lacks some ES2019+, `Array.flatMap` among it: `map` and spread.
- PipeWire link state reads `Unlinked` and node `properties` `{}` until a
  `PwObjectTracker` holds them.
- Quickshell types only plain media classes; `Audio/Source/Virtual`,
  `Stream/Input/Video` are untyped (0), with no `audio` (no volume, mute): use
  `properties["media.class"]`. `preferredDefaultAudioSource` refuses them:
  `wpctl set-default`.
- An IPC function named `show` collides with `qs ipc`'s subcommand.
- `systemctl is-active` exits non-zero for every state but active: a `Process`
  reading stdout, not a `Command`.
- A bind dispatching `hl.dsp.global` runs again on release, along with anything
  else in it: a global gets a bind of its own.
- Hyprland reports no lock-key changes; its `input.keyboard.key` event comes
  before the keyboard's new state.
- Hyprland's `screencast` event fires for any capture (grim, the shell's own
  previews) and ends 500 ms after the last frame: it cannot tell a screen is
  shared.
- A script the shell kills leaves its pipeline running until the next write: a
  long-running reader is a process substitution the script kills on exit.
- qmllint is wrong about `Edges.Bottom` into an `Edges` property (disable pair
  `incompatible-type`) and `PanelWindow`'s `margins` (size the window instead);
  it types `QsWindow.window` as `QObject` (use `Window.height`).
- An item sized from its `Row`'s implicit width while a child's width is
  clamped by the item's settles at zero, silently: size from the children's
  implicit widths (`Button.contentWidth`).
- `visible` reads false under a hidden ancestor: test what makes it visible
  (`text !== ""`).
- `Theme`'s fonts are points, so `font.pixelSize` is −1: a line's height is a
  `FontMetrics.height`.
- Quickshell sorts `SystemTray.items` by category and id (`TrayOrder` keeps
  arrival order).
- `notify-send -i /file` arrives as `image://icon//file`; `Notifs.picture`
  reads it as the file.
- A `Binding` with `when: !area.pressed` leaks its value mid-drag: set what a
  press holds in `onPressed` (`Slider`'s range).
- Under a disabled ancestor a `MouseArea`'s `enabled` still reads true: set its
  cursor explicitly.
- A `ShellScreen` dangles while its monitor goes ("dangling screen object"): a
  per-screen window takes its name once, in `Component.onCompleted`.
- Past a couple of dozen windows on a workspace Hyprland tiles some to negative
  sizes, and capturing one gets the shell killed (`wl_shm_pool` "Invalid
  stride"): no `ScreencopyView` of those.
- An item destroyed mid-`grabToImage` crashes Qt's render thread
  (`QQuickItemGrabResult::render`): a copy goes only once its grab is back
  (`NotificationPopups`).
- `RectangularShadow` leaks an inner `ShaderEffect` per instance (Qt 6.11,
  TODO.md): `Shadow` is a `ShaderEffect` on Qt's own shadow shader.
- A `Singleton` is created on first use, so an unread one's `IpcHandler` does
  not exist, and `qs ipc` says "Target not found." with exit 0.
- A value at the moment a state flips depends on binding order: derive it from
  what stays put.
- Switching `Layout.alignment` snaps: animate a `Layout.topMargin` bound to a
  property with a `Behavior`.
- A `ListView` row moving under a `displaced` transition keeps the place it
  aimed for when a row above changes height meanwhile: a list whose rows grow
  (the control centre's menus) has none.
- A `Behavior` whose duration follows the flag driving its value may start with
  the old duration: two `NumberAnimation`s from the flag's change handler.
- `Quickshell.Networking` exports `Network`, shadowing a singleton of that
  name: ours is `Net`. It picks its backend once, on first use (NetworkManager
  down then = no backend until restart; restarts later are handled).
- Quickshell asks NetworkManager for every access point at once and the system
  bus allows 128 pending replies: past ~128 networks the rest are missing
  (TODO.md; qs-test's bus raises the limit).
- Quickshell reads an MPRIS player the moment its name appears; properties set
  after are never read. Firefox drops `mpris:length` on a new track until a
  pause, so `Media.length` keeps the last one sent.
- hyprsunset's `temperature` getter keeps the last value through `identity`:
  the shell tracks night light itself.
- Bluetooth without an agent pairs only what needs no code; a failed `pair()`
  shows only as `pairing` ending without `paired`.
- A `ScriptModel` with `objectProp` keeps a delegate whose key stays: lists
  rebuilt from bindings keep their state (an open menu, a typed password) only
  through it.
- An `Instantiator` over a plain array rebuilds every delegate on each change
  (a process killed and run again, a watcher's state lost): a `ScriptModel`.
- A notification replaced in place is soon gone, and calling it throws: compare
  it, never call it, once replaced.

### Components: what the code does not say

- `launcher/`: one `LauncherWindow`, a `LauncherMode` per feature, each its own
  global shortcut (`quickshell:launcher-<name>`): SUPER+D `apps`, SUPER+V
  `clipboard`, SUPER+P `monitors`, SUPER+Tab `windows`, SUPER+N `nixpkgs`. A
  mode sets `rows` (unique `key`s keep delegates), `fields`, a `glyph` or
  `image`, optional `preview` and `find`. `search.js`: each word a substring,
  or a loose field's letters in order, or from four letters a word with one
  slip, ranked below. The card opens full height so it holds still while
  typing. `apps` ranks equal matches by `AppUsage` (frecency as one number, no
  decay) and warms every icon at start (an icon Papirus lacks costs thousands
  of stats). `clipboard` decodes each clip once into Quickshell's cache, pruned
  to what cliphist lists; it searches cliphist's preview, a clip's first 100
  characters. `monitors` lists the profile hyprmoncfgd would apply
  next first (`Recommended`), reloading a second after hotplug bursts.
  `windows` is wlr-foreign-toplevels in Hyprland focus order with live
  previews. `nixpkgs` searches nixos-unstable's ~130 000 packages
  (`nixpkgs-index` TSV, read and refreshed on first open, columns, own loop and memo, no slip pass: it would cost
  a pass over every row per key).
- `nixpkgs-run`: builds `github:NixOS/nixpkgs/<rev>#<attr>` with a progress card
  (`nixpkgs-progress.jq` over nix's internal-json), then runs it in a transient
  `systemd-run --user` service sandboxed by systemd: `ProtectSystem=strict`,
  `PrivateTmp`, tmpfs over `$HOME` and `$XDG_RUNTIME_DIR`, only PipeWire, X11
  and GTK/fontconfig/cursor settings bound back, no nix daemon or D-Bus.
  Wayland through its own `security-context` socket, so Hyprland hides
  protocols that type into or capture other windows (X11 apps still share
  Xwayland). Desktop-entry programs run alone, others in wezterm, held open on
  failure or a run under 5 s.
- `shortcuts/` (SUPER+?): `hyprctl binds -j` per open; numbered and directional
  binds folded, submap binds under the bind that enters, media keys out; up to
  three balanced columns, shrunk only when none fits.
- `tooltip/`: the tooltip layer per screen (overlay, no input), drawn only while
  `Tooltips` shows one there.
- `power/` (SUPER+X): five tiles, each key a keycap on it (pressed without Alt), Reload
  Hyprland, Restart to Firmware on UEFI; ending the session or machine takes a
  second press within 5 s.
- `bar/`: per screen. Workspaces led by the distro's logo (`Machine`, 22 px in
  a workspace's square); other monitors' workspaces still
  here are named after them (`DP2-1`, `WorkspaceOwners`, remembering connectors
  across unplugs). Quickshell refreshes monitors only as one comes and drops
  windows opened on a workspace it has not loaded, so `Bar.qml` refreshes on
  those events and 300 ms after a burst. The status button shows what records
  (`Privacy`), bell or Do Not Disturb, VPN, link, Bluetooth, a muted mic,
  volume, battery, a cup while Caffeine is on; the wheel steps the volume. The
  tray (`Tray`) shows its first three icons and "+N", and every icon while the
  pointer is in `BarWindow`'s right-end zone, which is the buttons' parent (hover
  reaches ancestors, not siblings beneath).
  `TrayMenu` (panel `tray-menu:SCREEN`) cascades as GTK's, takes the keyboard,
  closes as the pointer leaves unless keys drive it.
- Caffeine (`controls/Caffeine.qml`, IPC `caffeine toggle|set|active`) is the
  `caffeine.service` user unit (`systemd-inhibit --what=idle`), so it outlives
  a shell restart.
- `weather/`: MET Norway for the time zone's city (`/etc/localtime` via
  `zone.tab`, no address lookup), every half hour and when a suspend skipped
  one. MET's icons fetched by `quickshell.nix`.
- `notifications/`: the daemon and popups. `Notifs` keeps each as a `NotifEntry`
  until dismissed, a second past close so views slide it away. Popups go to the
  monitor focused on arrival, five at most; over a fullscreen window only
  critical ones. Same card updates in place for a stack tag
  (`x-canonical-private-synchronous`, `x-dunst-stack-tag`), an id, or the same
  app, summary and body within 2 s. Past 30 a second (critical apart) a flood is
  turned away and summed in one card, and an update in place only updates its
  card (no reorder, popup or sound); text is cut before layout (a megabyte held
  the shell for seconds); newest three per app, 100 in all. Body markup filtered
  to the spec (`markup.js`). elementary OS sounds via `pw-play`, one per 300 ms.
  `History` saves atomically to the state dir (no transient ones, 7 days,
  `history.js`), with copies of pictures only the server held, grabbed off
  screen once. IPC `notifications toggleDnd|setDnd|dnd|count|clear|hidePopups`.
- `center/`: GNOME's date menu under the clock: the last-playing player's
  `MediaCard`, notifications grouped per app, calendar (ISO weeks) and weather
  where there is room. Opening it checks all, puts popups away and sorts the
  groups; while open a group keeps its place as its notifications go, a new app
  comes in on top. Clear slides every group in view off at once (each its own
  swipe) and dismisses the rest unanimated, no Undo; a card whose group gained
  one mid-slide comes back. Collapse All also shuts each card's More. Do Not
  Disturb is a switch in its footer.
- `controls/` (SUPER+A): GNOME's quick settings: `Header` (the battery, or
  without one the machine), `Levels` (the volume, its arrow
  opening Sound: Output and Input, a symbol per device from its PipeWire
  properties, `devices.js`, and Audio Settings (pwvucontrol, whose meters
  Privacy already skips as passive); no mic mute; dim but for the arrow
  with a microphone and no output; each backlight), the `Pill`s
  the machine has (`Controls.toggles`), a `Menu` under the row that opens it (one slot
  per row, so its menus swap in place),
  `InUse` while something records. Backends are singletons: `Net`
  (Quickshell.Networking for Wi-Fi and wired, `nmcli` for VPNs; a captive
  portal gets a card; Wi-Fi without internet offers Sign In too, as a portal
  blocking DoT reads as limited: `nmcli device modify` gives the connection,
  not the profile, DHCP DNS without TLS, `device reapply` once online), `BluetoothDevices` (pair, trust, connect in one click; a
  PIN device goes to bluetui), `Volume`, `Microphone`, `NightLight`
  (hyprsunset, state kept and restored when hyprsunset restarts), `Media`,
  `Power` (UPower display device), `Privacy` (a capture stream from a mic while
  audio flows, meters and passive filters aside; a portal screen cast; a camera
  via PipeWire or open on `/dev/video*` for half a second, `camera-users`).
  `names.js` makes device and network names safe for one line.
- `osd/`: what just changed, on the focused monitor, 1.5 s, bottom centre 4 em
  up. `Osd` shows changes as made, not states as found: each `Watch` takes in
  values arriving within 500 ms of its key or readiness changing (startup,
  PipeWire restarts, a new output's own volume show nothing); each
  `DeviceWatch` shows a new default only once settled (400 ms) and different.
  Brightness from `backlight-watch` (`udevadm monitor` on backlight uevents,
  `name brightness max;` per line). Caps Lock: Hyprland's `input.keyboard.key`
  sees key 66 go up, dispatches `quickshell:caps-lock`, the shell reads
  `hyprctl devices -j` then and 150 ms later. The volume and brightness keys
  also dispatch `quickshell:osd-volume` / `osd-brightness` (own binds), so a
  level at its end still shows.

## Build, check, format

```bash
host=thonkpad

nixos-rebuild switch --flake ".#$host" --sudo     # as the user: root cannot read the checkout
nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel"
nix build --no-link --print-out-paths ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"

nix flake check          # the checks below; skips aarch64-darwin unless --all-systems
nix fmt                  # nixfmt-tree; keep the tree clean
```

Always `--no-link`; never leave a `result` link in the tree.

Checks (`modules/flake/checks.nix`): `format` (`nixfmt --check` everywhere),
`eval` (Linux: every host's and installer's `toplevel.drvPath`). From
`quickshell.nix` (Linux):

- `qmllint`: `qs-lint` (`scripts/qs-lint.sh`) over every host's built shell,
  failing on any warning (`--json`, as text output drops some). It writes the
  `qmldir`s Quickshell makes for `qs.*` and mends Quickshell's type info
  (`_GlobalShortcuts`' missing `depends`, opaque stubs, unqualified
  `FileView.adapter` / `Bluetooth.defaultAdapter`, `DBusMenuHandle`'s base), so
  only `uncreatable-type` is off. Where qmllint is wrong:
  `// qmllint disable <category>` … `enable`. Then `qs-design-lint`
  (`scripts/qs-design-lint.sh`): non-Theme colours (literals, `Qt.rgba`, a
  `Qt.tint` of anything but Theme), typed radii, non-token durations and fonts,
  icon paths outside `Symbols`, symbols at sizes GNOME doesn't use (16, 24, 32,
  64, 128), shadows off a `Card`, hand-turned arrows instead of
  `ExpanderArrow.pointing`, an inline component name in two files or shadowing
  `common/`, `flatMap`, text ending in a full stop, an ellipsis on a settings
  item, a `MouseArea` naming no cursor, a plain space between number and unit.
  Deliberate exceptions are listed in the script with why.
- `notification-markup`, `notification-history`, `launcher-search`, `names`,
  `sound-devices`: `qmltestrunner` over
  `tests/tst_{markup,history,search,names,devices}.qml`, each with
  only its script beside it (`qmlTest`).
- `qs-test`: builds the package, so shellcheck runs over `scripts/qs-test.sh`.

## External consumers

The mac (separate nix-darwin flake) imports
`modules.homeManager.{wezterm,neovim,pi-agent}`. Keep them platform-neutral
(guard Linux-only packages) and expose what the mac sets as aspect options.

## Testing the Quickshell shell

Never test in the live session. `qs-test` (`scripts/qs-test.sh`, flake package
`qs-test`) runs the host's Hyprland and config, built from the checkout, nested
in a headless labwc, with its own D-Bus (session and system), `XDG_RUNTIME_DIR`
and PipeWire. Nothing reaches the live session.

- labwc lends Hyprland a GPU (Hyprland binds `xdg_wm_base` 6; sway and cage
  offer 5). libseat points at a seatd that doesn't exist, so Hyprland never asks
  logind for DRM; `HYPRLAND_NO_SD_*` keep it off the user's systemd.
- Config: the host's `hyprland.lua` less `hyprland.start` handlers and monitor
  rules, plus the test's headless monitors (ids from 0, as on the machine).
- Input: `qs-input` (`scripts/qs-input.c`), one virtual pointer and keyboard for
  the whole session over a socket (a device per call drops seat capabilities
  and loses events), with the host's keymap (`super+shift+plus` is SUPER+?).

Build once, set `QS_TEST_DIR` to your scratchpad:

```bash
export QS_TEST_DIR=<scratchpad>/qs-test
qst() { "$(nix build --no-link --print-out-paths "path:$PWD#qs-test")/bin/qs-test" "$@"; }

qst up                         # the checkout's Hyprland config and shell for this host (path:, so untracked files count)
qst ipc panels open apps       # qs ipc call, with a timeout
qst gallery                    # every common/ piece in every state (tests/Gallery.qml)
qst key super+d                # through Hyprland's bind and the shell's global shortcut
qst type fire
qst key ctrl+n Down Return     # one key per argument
qst pointer 960 21             # absolute motion, layout coordinates (a warp may not hover)
qst click                      # left, where the pointer is; or `qst click right 1889 20`
qst click ControlsPanel:pill:wifi   # on the area named so ([WINDOW:]objectName, an enabled one first); `... 80 0` that far off it
qst area ControlsPanel:row:wg0 # where it is, as "x y"; a miss lists the names there
qst drag 1631 112 320 0 250    # press at x y, move dx dy over ms, release
qst wheel 3                    # notches, positive down
qst spin 5                     # five one-notch events at once, a wheel spun hard
qst layers                     # layer surfaces up, per monitor
qst shot apps                  # numbered PNG in $QS_TEST_DIR/shots, path printed
qst shot crop "360,330 600x260"
qst shot dp2 DP-2              # one monitor (the whole layout renders at the highest scale)
qst monitor add DP-2 2560x1440 1.25   # hotplug; `monitor remove|disable|enable DP-2`
qst monitors                   # Hyprland's, disabled too
qst focus DP-2
qst output 2560x1440 1.5       # the first monitor's mode
qst state                      # what the shell sees (JSON); `qst state '.popups | map(.screen)'`
qst wait '.panel == ""'        # until it holds (5 s, or `qst wait FILTER 10`), else fail printing the keys it reads
qst stays '.panel == "apps"' 2 # fail if it stops holding within 2 s
qst reset                      # monitors from QS_TEST_MONITORS, no windows, fresh qs without state
qst run                        # every case, sessions side by side (-j N), longest first
qst run chaos 'controls:VPN'   # a file, or its cases matching a regex
qst run --changed --fail-fast  # scenarios the checkout's changes reach
qst run --failed               # only the last run's failures; `--failed-first` all, those first
qst red [REV] controls:VPN     # those cases on REV's QML (HEAD) with the checkout's tests, in this session: each must fail
qst jobs [FILE[:REGEX]...]     # what a run would take, in order
qst timings                    # last run's slowest cases and phases
qst trace                      # this case's qst calls, by seconds into it
qst flood 3000 --urgency 2     # notifications over D-Bus (--apps N, --summary/--body LENGTH, --rate N)
qst tray                       # a tray item with nested submenus; `tray log`, `tray add first 4`, `tray remove first`, `tray clear`
qst x notify-send -a Discord loft01 hello   # anything inside the session
qst pipewire restart           # or stop, start
qst backlight intel_backlight 40 [MAX]      # fake backlight; `NAME remove`
qst camera open zoom [video1]  # `close zoom`, `add video1 [locked]`, `unlock video1`, `remove video0`
qst network wifi add Cafe 40 open # the fake NetworkManager: wifi add SSID [STRENGTH] [SECURITY] [PASSWORD], wifi remove|strength|clear,
                               # wifi many 300 [PREFIX], wifi json JSON, device add|remove NAME [wifi|ethernet], cable NAME on|off,
                               # profile wifi|ethernet|wireguard|vpn NAME [SSID PSK], vpn NAME ok|fail|secrets, up NAME,
                               # connectivity none|portal|limited|full, switch on|off, delay MS, dump, stop|start|restart
qst battery 15 discharging 1800             # PERCENT [charging|discharging|full|pending [SECONDS]], or remove
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70
qst player add spotify Spotify Playing [ART]   # MPRIS; status NAME STATE, remove NAME, clear
qst sync                       # copy edited QML in, restart qs, print warnings
qst problems                   # warnings less tests/known-warnings and this case's expects
qst census                     # what the probe finds wrong on screen
qst areas [REGEX]              # mouse areas: x, y, label, enabled, clicks, hand
qst cursor 960 21 [hand]       # the cursor Qt sets there
qst cursors [WINDOW]           # every clickable area asks for a hand
qst motion start               # record items per frame; `motion stop` fails on a jump
qst fail cliphist exit         # or crash, missing, garbage; `fail cliphist off`
qst expect [--may] 'hyprmoncfg'   # this case must (or may) log a warning matching it
qst actions                    # what the session tried to run on the machine
qst lint                       # the qmllint check on the checkout
qst down                       # kill and delete the session(s) and the test shell's state
```

### The session's fakes

- `systemctl`, `loginctl`, `pw-play`, `xdg-open`, `nixpkgs-run`, `nixpkgs-index`, `brightnessctl`
  and `hyprmoncfg` log to `qst actions` (`hyprmoncfg status` replays the live
  profiles; fake profiles in `$QS_TEST_DIR/cfg/hyprmoncfg/profiles`).
  `systemd-run --scope` logs and runs in the session. `hyprctl` is the test
  Hyprland's, `hl.dsp.exit()` only logged. cliphist reads a copy of the DB.
  `systemctl --user start|stop|is-active` keeps state in `$QS_TEST_DIR/units`.
- Config dir: the user's, symlinked, except `hypr/` and `hyprmoncfg/`.
- qs at `QT_SCALE_FACTOR` 1 unless `QS_TEST_SCALE`, with `TZDIR` (Qt needs it
  on NixOS). `bar fakeOutputs 1000` fakes 1000 outputs; `realVolume` drops them.
- System bus: python-dbusmock templates via `qs-dbusmock`, fresh per case:
  NetworkManager (`tests/networkmanager.py`; wired + wg0 up, three networks,
  unless `QS_TEST_NETWORK=none`), UPower (`tests/upower.py`; battery 76 %
  discharging), BlueZ (`tests/bluez.py`; an adapter, unless
  `QS_TEST_BLUETOOTH=none`). `nmcli` is real except `connection up`, which asks
  the fake (libnm won't register an agent with a non-root NetworkManager), and
  `device modify|reapply`, only logged.
- MPRIS players (`tests/mpris.py`) on the session bus, one mock each, named
  as they start.
- PipeWire on `tests/pipewire.conf`, WirePlumber on `tests/wireplumber.conf`:
  null outputs Speakers (default, 64 %), Headphones, HDMI / DisplayPort; test-tone
  mics Microphone (default) and Headset Microphone; a virtual Noise Cancelling
  source. A `pw-cli create-node` node gets no ports, so never becomes default; to
  take the default away, destroy a test mic (`pw-cli destroy test-headset-mic`).
- `backlight-watch` and `camera-users` are real, on `$QS_TEST_DIR/backlight` and
  `$QS_TEST_DIR/dev`; `udevadm monitor` replays what `qst backlight` appends.
  The brightness keys run the host's brightnessctl, which reaches the real
  backlight: drive `quickshell:osd-brightness` and `qst backlight` instead.
  The volume keys reach the session's PipeWire.
- hyprsunset runs in the session.

### Session notes

- `sync` copies files and restarts qs (a hot reload keeps inline components'
  old types). `reset` does not re-copy. A palette, `Symbols` or Hyprland config
  change needs `down` and `up` (they live in the built `nix/`).
- `run` copies the working tree per case: to test a commit while editing, use
  a `git worktree` with `QS_TEST_REPO` pointing at it.
- One `qst` at a time per `QS_TEST_DIR` (`run` holds a lock). `run -j N` uses `$QS_TEST_DIR/w1…wN`,
  kept up for the next run; `down` them, or leftover sessions exhaust
  Xwayland's 33 displays and Hyprland dies with "CBackend::create() failed".
- Each window in the copy gets a `ProbeWindow` (`tests/ProbeWindow.qml`) naming
  its file; the probe labels items `File/Type`.
- Never `pgrep -f <pattern> | xargs kill`: the pattern matches your own shell.
  `down` finds processes by runtime dir and D-Bus address; `stop_qs` kills qs's
  process group (its inotify watchers outlive it otherwise).
- Each `qst` is a `writeShellApplication` whose PATH puts real tools ahead;
  `enter` puts the session's `bin/` back in front.
- Shots: the cursor a surface asked for shows only after the pointer moves over
  it once mapped; thin grey lines are headless-output artifacts. Animation:
  `qst motion`, or background `qst x grim -s 0.25` ~35 ms apart and `md5sum`.
- `notify-send -A` waits: background it. Tray menus close on a click elsewhere,
  their icon, or Escape.
- Quickshell keys state and cache dirs by config path; `down` deletes only the
  test shell's.

### State and scenarios

`qst state` is `tests/Probe.qml` (IPC target `probe`, only in the session's
copy): panel, screens and monitors, workspaces, windows, popups, notification
history, DND, volume, microphone, OSD, brightness, caps, privacy, the status
button's glyphs, controls and its backends, tray, tray menu, the focused
control and `ring`, `hovered` (pieces lit by the pointer), tooltip, sliders,
launcher `results`, `center` (groups with `y`, `slid`) and `centerMore`,
`machine`, `field`, `problems`, `layers`, `hypr`. A field a
test needs goes in the probe, read through the shell's own singletons.

Every snapshot also checks the whole shell:

- `problems` (the census): text with no room or under 8 pt, contrast below 3:1
  (Theme's faint colour and fading text aside), colours and radii not Theme's
  (a running `Behavior on color` is held to its target),
  images without source or failing, a disabled area setting a hand, a card off
  its window, text over text, a window that is not a layer surface.
- `invariants` (`tests/invariants.jq`): an open panel has its layer and vice
  versa, nothing on `FALLBACK`, popups only on real screens and five at most,
  three per app past the popped up, history within 100, a probe answer within
  2 s, a countdown never going back up.

`wait`/`stays` fail on a problem lasting 500 ms (a transition passes through
some), and at once on the countdown. A case fails on any warning qs logs, less
`tests/known-warnings` (regex, tab, why) and its own `expect`s; on qs peaking
past `QS_TEST_PEAK` MiB (1024, `VmHWM`); on an `IpcHandler` in the source that
isn't registered.

`tests/scenarios/*.sh` run under `set -euo pipefail` with `qst` on PATH. Each
`qst case "what should happen"` resets; a file sets `QS_TEST_MONITORS`; lines
before the first case are shared helpers; no case may use what an earlier one
set. Assert with `wait`/`stays`, never `sleep` (`run` refuses one without
`# sleep: why`). A case timing against the machine says `# alone: why` and runs
with nothing beside it. `--changed` maps changed files to scenarios
(`changed_scenarios` in `qs-test.sh`): a `common/` type through the files that
use it, the probe alone to all, all for an unknown file.

A failing case prints the line it failed at, its last `qst` calls
(`qst trace`) and, for a `wait`/`stays`, only the state's keys its filter reads;
the whole state is in `$QS_TEST_DIR/failed-state.json`, the run's output in
`~/.local/state/qs-test/last-run.log`. Click areas by name, not by a scenario's
own `qst areas` filter: a missing name then says what is there.

| Scenario | Covers |
| --- | --- |
| `binds.sh` | every global bind opens its own panel and closes it |
| `caffeine.sh` | Caffeine's unit, pill and status cup |
| `chaos.sh` | hostile and broken clients: floods, megabytes of text, bad icons, panel and hotplug storms, 40-window workspaces, 60 outputs, damaged state, 200 tray items, 300 hostile network names, 1000 outputs, 50 VPNs, 100 BT devices, small and 4K screens |
| `controls.sh` | the control centre: open/close paths, status glyphs, header (battery or machine), every pill and menu against the fakes, a password tried as the centre shuts, two VPNs at once, a failed connect mid-scan, the sound menu's headings, symbols and Audio Settings, services stopping under it |
| `cursors.sh` | the bar and every panel's cursors, a closed hand mid-drag |
| `design.sh` | every surface on screen, scaled too, for the census |
| `failures.sh` | the shell's tools failing (`qst fail`) |
| `history.sh` | saved history across restarts and in-place reloads, kept pictures, damaged files |
| `hotplug.sh` | unplug, disable, replug under every panel, menus and popups |
| `idle.sh` | the idle dim under `motion`, clicks through it, the lock command's holds |
| `interactions.sh` | fixes that had no case: popups, wheel past 100 %, clip scope, 1024x600, power keys, hover after a panel closes |
| `launcher.sh` | typing as it opens, open time, clicks on another monitor |
| `motion.sh` | center groups expanding, the OSD fading |
| `notifications.sh` | per-app limits, five popups, stack tags, DND, the bell, flood sounds, bare-path pictures, Clear, groups holding their places, Collapse All shutting More |
| `osd.sh` | what shows and what must not |
| `privacy.sh` | mics real and virtual, casts, cameras via PipeWire and `/dev` |
| `tray.sh` | the tray strip, its menus and keys |
| `workspaces.sh` | windows opened while the shell starts, the wheel spun hard |

Behaviour that broke once gets a case; check it fails without the fix:
`qst red` (only QML; a fix elsewhere needs a `git worktree` and `QS_TEST_REPO`).

What Hyprland does that tests run into:

- With no monitor on, Hyprland adds a headless `FALLBACK`; Quickshell lists it.
- Removing any monitor focuses the first.
- A connector gets back its last id unless taken, else the lowest free one,
  kept from then on; `reset` holds ids with placeholders to give 0, 1, … back.
- A monitor rule without `disabled = false` leaves a disabled monitor off;
  qs-test writes it in every rule.
- Going to and from no output, Qt warns "Layershell screen does not correspond
  to a real screen"; `problems` drops those right after "creating placeholder
  screen".
- In jq a pipe binds loosest: `(.popups | map(.screen)) == [...]`.

## Sharp edges

- **`skinke.net` resolves through the `wg0` NetworkManager profile**, which
  this flake does not own: `ipv4.dns 10.0.0.1` and route-only `~skinke.net`,
  hand-made in `/etc/NetworkManager/system-connections`. `nmcli connection
  modify` only edits the keyfile: `nmcli connection up wg0` (or
  `nmcli device reapply wg0`) to reach resolved. Tunnel down, `~.` answers from
  public DNS silently.
- **Hosts**: each is a directory; `imports.nix` declares it and its aspects,
  siblings add to `"nixosConfigurations/<name>"`, `home.nix`/`monitors.nix` to
  `…/home`. Hardware stays per host (`hardware.nix`) even when repeated. Both
  homes import `homelab`.
  - `thonkpad`: `base workstation gaming`; Intel laptop, `thermald`, TLP
    thresholds, UPower, disko, `treefmt`; for Chromecast 5353 and, for 10 s, the
    port an outgoing mDNS or SSDP query left from (nftables set `discovery`).
  - `desktop`: `base workstation gaming moonshine`; AMD, RX 6700 XT, ZSA udev
    rules, disko, hyprmoncfg profiles `default`/`left-only`/`right-only`,
    nix-index, startup apps pinned to monitors, `quickshell.scale = 1.2`.
- **Profiles**: `base` (nixos: `boot doas documentation git home-manager
  journald locale network neovim nix nixpkgs packages podman unstable-nixpkgs
  users`; HM: `git pi-agent tmux users xdg-user-dirs zsh`), `workstation`
  (nixos: `display-manager fonts gtk hyprland plymouth sound`; HM: `bluetooth
  cursor desktop-apps gtk hyprland neovim qt wezterm`). The NixOS half pulls in
  the HM half.
- **Theme** (`modules/theme/`): `palette.nix` declares `palettes`; `fonts`
  nixos, `gtk` both, `cursor` and `qt` HM. GTK4 recoloured through libadwaita's
  `:root` variables (dark only), GTK3 through adw-gtk3's `@define-color`, both
  in the user `gtk.css`; Qt's adwaita-dark keeps its own.
