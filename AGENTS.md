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
| `hyprland.workspaces` | int 1–9 (a digit key each) | Workspaces per monitor; hyprsplit, binds, the bar |
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
  `lib.trivial.release` (`home-manager.nix` does the same for
  `home.stateVersion`): a deliberate exception, so a release bump also bumps
  both, migrations included. Imports
  `flake.modules.nixos."nixosConfigurations/<name>"`.
- **`offline-installer.nix`**: per host, `nixosConfigurations.offlineInstaller-<host>`:
  an install CD carrying the host's `toplevel` and disko `destroyFormatMount`,
  substituters, channels and ZFS off, root autologin, keymap/locale/timezone
  from the host, and `offline-installer` (disko asks `yes` before wiping, then
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
| `desktop-apps.nix` | HM | `desktop-apps` | GUI apps every workstation gets; Loupe, Celluloid and Papers the default image viewer, video player and PDF viewer through `~/.local/share/applications/mimeapps.list` (below the mutable `~/.config/mimeapps.list`, which apps write and "Open With" overrides); Celluloid on an mpv.conf (`hwdec=auto-safe`, its default is software; `profile=fast`) and graphics offload via dconf |
| `display-manager.nix` | nixos | `display-manager` | ly |
| `doas.nix` | nixos | `doas` | doas replaces sudo (`doas-sudo-shim`); wheel `noPass`, no `keepenv`, passes only `LANG`, `NIX_PATH`, `SUDO_*` (plus the module's own `SSH_AUTH_SOCK`, `TERMINFO`, `TERMINFO_DIRS`) |
| `documentation.nix` | nixos | `documentation` | NixOS manual, info pages and `/share/doc` off; man pages kept |
| `gaming.nix` | nixos | `gaming` | Steam + proton-ge |
| `git.nix` | nixos, HM | `git` | git, identity from `identity` |
| `home-manager.nix` | nixos | `home-manager` | HM for `identity.username`, `useGlobalPkgs`/`useUserPackages`, `backupFileExtension = "hm-bak"`; pulls `nixosConfigurations/<host>/home` |
| `homelab.nix` | HM | `homelab` | just, kubectl, helm, virtctl, kubelogin, `programs.gh`, ssh `loft01` forwarding 6443; both homes import it |
| `hyprland/` | nixos, HM | `hyprland` (+ `hyprland.workspaces`, HM `hyprmoncfg.profiles`, `quickshell.scale`) | below |
| `journald.nix` | nixos | `journald` | 90-day retention |
| `locale.nix` | nixos | `locale` | `no`/`nodeadkeys`, `en_DK.UTF-8`, Europe/Oslo, timesyncd; hyprland reads xkb via `osConfig` |
| `moonshine/` | nixos | `moonshine` | below |
| `nautilus.nix` | nixos, HM | `nautilus` | Nautilus, Sushi (Space) and LocalSearch (full-text search; its `ConditionEnvironment=XDG_SESSION_CLASS=user` reset, as only gnome-session imports it) from `pkgs.unstable` until NixOS 26.11: GNOME 51's Sushi is GTK4, which attaches to Nautilus over xdg-foreign v2 and floats by itself (50's GTK3 wants v1, which Hyprland lacks); the GNOME module's thumbnailers (glycin, GStreamer, EPUB; PDF from desktop-apps' Papers); gvfs; `inode/directory`; xdg-desktop-portal-gnome for FileChooser alone, so GTK4's file dialogs are Nautilus (floating over a parent, tiled without one). HM: Create Link and Delete Permanently in its menus; Sushi never takes the focus, not even as it asks on each file, so Nautilus' keys move it and Space closes it |
| `neovim/` | nixos, HM | `neovim` (+ HM `neovim.outOfStorePath`) | below |
| `network.nix` | nixos | `network` | resolved with DNS-over-TLS to Quad9, no plaintext fallback; NetworkManager (stable MACs, wifi powersave off, no auto wired profile; connectivity checked against Arch's plaintext `nm-check.txt`, without which no captive portal is ever reported); nftables; no ping; rp-filter `loose` (WireGuard full tunnels) |
| `nix.nix` | nixos | `nix` | GC, `auto-optimise-store`, flakes, cache, no global registry; `nixpkgs` registry/`NIX_PATH` from `nixpkgs.flake.source` |
| `nix-index.nix` | HM | `nix-index` | small prebuilt DB + wrapped comma |
| `nixpkgs.nix` | nixos | `nixpkgs`, `unstable-nixpkgs` | `allowUnfree`; overlay `pkgs.unstable`. Prefer default `pkgs` unless a package needs unstable |
| `packages.nix` | nixos | `packages` | jq, fzf, fastfetch, tree; NixOS' `defaultPackages` (perl, rsync, strace) off |
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
`main`), via its NixOS module (which disables nixpkgs' and builds the package
against our nixpkgs, so its glibc matches the host's drivers). Each Moonlight
stream gets its own headless compositor at the client's mode. One app: Steam
`-gamepadui` in gamescope, `DISABLE_FERRISCOPE_WSI`, `--xwayland-count 2` (on
one Xwayland a game loses X focus to the overlay and never comes back), Deck UI
(Big Picture `-tenfoot` froze the stream). User joins `input` (virtual pads);
the service itself runs in `moonshine`, the group its sleep-inhibit polkit rule
allows, so `moonshine healthcheck` from a terminal fails that check while the
service passes it. A desktop Steam is shut down first
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
formatters, `gcc`, `go` (gopls' root detection), `tree-sitter`, `fzf`,
`wl-clipboard` (Linux) are `extraPackages` (nvim's PATH only); ripgrep and fd
come from `programs.ripgrep` / `programs.fd`. LSP overrides in `after/lsp/`. HM's own `init.lua` is
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
`release-26.11` ships it) with `pi-coding-agent` from `pkgs.unstable`, or on
the mac (no overlay) `inputs.nixpkgs-unstable` imported with `allowUnfree`
(`claude-code` is unfree). `extraPackages` suffixes `git`, `nodejs`,
`claude-code` and what agents reach for (python3 with pyyaml, yq-go, dig,
`file`, openssl, unzip, xxd) so a project shell's win (nixpkgs' wrapper already
prefixes `rg` and `fd`); these are on pi's PATH only, never the user's. Writes into
`config.programs.pi-coding-agent.configDir` (`~/.pi/agent` by default):
`settings.json` (with `mutableSettings = true`, so activation merges declared
settings in place while pi can still write its own keys like
`defaultProjectTrust`; provider, model and thinking level `mkDefault`s —
`pi-claude-bridge`'s Claude Opus 5.5 at `high`; Copilot's Claude Opus 5.5
through `modelThinkingLevels`), `models.json` (DeepSeek V4.1 Flash at its
agentic evals' `top_p` 0.95, temperature 1), `APPEND_SYSTEM.md`
(`appendSystem`), `claude-bridge.json` (its `pathToClaudeCodeExecutable` is the
store's `claude-code`, since the Agent SDK's bundled CLI cannot exec on NixOS),
the `commit-style` and `design-board` skills, a `bell` extension (BEL on finish
or prompt) and `tmux-session` (session file in pane option `@pi_session`). pi
packages are pinned in `settings.packages`, installed by pi with nixpkgs' `npm`
into `~/.pi/agent/npm`.

Sharp edges: with `mutableSettings = true`, removing a declared key from
`settings` does not delete it from the existing `settings.json`; delete it by
hand. pi themes cannot paint the background (no global token); it is wezterm's.
The bridge spends Claude Code's login, not pi's: `claude auth login` per
machine, then `claude-bridge/...` models (never `anthropic/...`, which is pi's
own provider and does not use the subscription). Skill boards are plain
`file://` pages in `~/.local/share/design-board/`; Copy uses
`navigator.clipboard` and, if the browser refuses it, selects the textarea
instead (Ctrl+C). The engine's own chips use `data-scen`/`data-next`, so a
board's `data-act` verbs (all but `noop`) reach its `onAct`.
A board is scaffolded by `new-board.sh` (the engine copied, only `board.js` and
`board.css` written per round) and checked by `check.mjs`: headless Chromium
over the DevTools protocol in real time, `nix shell nixpkgs#chromium` when none
is on PATH; a page without `BOARD` or questions fails.

### `hyprland/`

Files: `default.nix` (nixos + HM base), `bindings.nix`, `rules.nix`,
`hypridle.nix`, `hyprlock.nix`, `hyprmoncfg.nix`, `hyprtoolkit.nix`,
`plugins.nix`, `quickshell.nix`, `swappy.nix`, `assets/`, `scripts/`, `tests/`,
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
  never twice: a `flock` in `$XDG_RUNTIME_DIR` decides, let go before the
  final `idle unlocked` so a lock asked for meanwhile still comes, and `pidof`
  for one run by hand. It runs in a scope of its own (`systemd-run --user
  --scope`), so a switch restarting hypridle leaves the lock up. Under an idle
  dim it asks the shell its darkness (`idle hold`, which also freezes the dim)
  and starts hyprlock on a copy of its config (`$XDG_RUNTIME_DIR`) with brightness 0.6 ÷ (1 − darkness), so every lock ends
  on the same picture. `on_lock_cmd` (`idle locked`) drops the dim and blocks
  new ones; `on_unlock_cmd` and `lock` exiting (`idle unlocked`) clear all.
  hyprlock dying by a signal is started again, three times at most
  (`allow_session_lock_restore`), so a crash never needs a TTY.
- **Idle dim** (`quickshell/idle/`, layer `quickshell:idle`): 10 s before the
  lock hypridle runs `qs ipc -c shell call idle fade 10 0.4` (0.4 black for
  hyprlock's 0.6), its resume `cancel`, so input brings the screens back. A
  fingerprint unlock (no input) clears it through `on_unlock_cmd`. hypridle is
  the one clock and input watcher; without a shell the lock just comes. Sleep
  and the power menu lock at once. A fade whose lock or cancel never comes
  (hypridle restarted mid-fade) lifts 10 s after it ends, and a hold whose
  lock never comes (the lock command killed after `hold`) 10 s after it.
- **hypridle is `pkgs.unstable.hypridle`** (0.1.8): 0.1.7's single inhibit counter
  loses logind's idle inhibitor to a stray ScreenSaver `UnInhibit` and an app
  disconnect, so Caffeine stopped keeping the lock off. Drop the pin when
  nixpkgs moves to 26.11.
- **Screenshots**: one `writeShellApplication` (`scripts/freeze-region.sh`),
  the screen frozen while slurp selects. `copy` (SUPER+Q, the control
  centre) puts the region on the clipboard, silently; `edit` (SUPER+SHIFT+Q)
  opens it in Swappy (`swappy.nix`; red rectangles to start, the panel shown,
  Ctrl+C copies and Ctrl+S saves to `~/Pictures/screenshots`, either
  closing it, silently). It floats and centres by itself, its window fixed to
  the shot (up to 75 % of the screen; Hyprland's `size` and `min_size` rules
  do not reach a window that cannot resize), a rule keeps the focus on it,
  and it opens in about a third of a second;
  Satty took a second (GTK4, libadwaita and a GL canvas), and Flameshot 13
  freezes only the first monitor under Hyprland. Escape in slurp sends
  nothing; a failure is a critical "Screenshot Failed".

## The Quickshell shell (`hyprland/quickshell/`)

[Quickshell](https://quickshell.org) 0.3.2 from `pkgs.unstable` (0.3.1 fixed
crashes on freed objects in a `ScriptModel`), patched until upstream has the
fixes: `quickshell-image-data.patch` drops an `image-data` hint whose sizes
outrun its bytes (read past its end, any client could crash the shell) and
honours the client's rowstride; `quickshell-crash-relaunch.patch` has a crash's
relaunch and its reporter each open the instance's memfd anew (on one shared
offset the relaunch sometimes read nothing and started with no config);
`quickshell-service-restart.patch` registers a NetworkManager device once
(starting again, NetworkManager named each twice) and follows BlueZ going and
coming (gone, its adapter stayed; started late, it was never seen);
`quickshell-fileview-commit.patch` fails a save whose atomic commit failed (a
full disk read as saved). The shell `qst clock` moves is the same build on the
system malloc. `quickshell.nix`
runs it as `quickshell.service`: restarted when the shell changes
(`X-Restart-Triggers`), 1 s after a crash, no start limit (hotplug bursts),
`MemoryMax=2G` without swap (it sits near 500 MiB; past it the kernel kills
it, `Result=oom-kill`, which `Restart=on-failure` restarts, as a transient unit
showed),
`QS_PIPEWIRE_IMMEDIATE_RECONNECT=1` (without it PipeWire not up as the shell
starts is never connected to). Quickshell's own guard also restarts a crashed
instance in place, an exec under the same pid, and logs "Quickshell has crashed
under pid N" (the pid of a core-dump child, not the shell's); what the crashed
shell ran stays its child until its next write fails.

Components: `bar/`, `center/`, `controls/`, `launcher/`, `notifications/`,
`osd/`, `power/`, `shortcuts/`, `tooltip/`, `weather/`, `idle/`; `shell.qml`
only instantiates them, once `qs list -p` shows no older shell of this config
on this display (one run by hand beside the unit's quits before it shows anything; a failed
check starts it anyway). `common/` holds what several share: the STYLE.md
pieces, `Theme` (only it reads `Colors`), `Panels`, `Overlay`, `Popover`,
`ClickAway`, `Screens`, `Time`, `StateFile`, `Command`, `Deadline`, `Watcher`, `Detached`, `WheelSteps`,
`WorkspaceOwners`, `Tooltips`, `Machine` (os-release's `LOGO=` through the
icon theme, hostname, uptime).

### Wiring

- **`Panels`**: the one open panel by name; opening one closes the others;
  nothing opens with no monitor on (it would land on `FALLBACK` holding the
  keyboard). The center and the control centre are one per screen, so a clock
  opens its own and another's never moves a window still fading out. IPC
  `panels open|close|toggle <name>`: `apps`, `clipboard`,
  `monitors`, `windows`, `nixpkgs`, `shortcuts`, `power`, `gallery` (qs-test
  only, which adds itself to `Panels.names`), per screen `center:DP-1`,
  `controls:DP-1`, `tray-menu:DP-1` (a tray menu opens only from a press on
  its item; named alone it closes again); `center` or `controls` alone is the
  focused screen's. Any other name opens nothing (an unknown one warns): open,
  it would hold the clicks and the popups with nothing shown. A screen's panel
  closes as the screen goes from `Screens.real`. `Panels.center` is any open
  center.
- **`Overlay`**: the full-screen layer a panel lives in; a click off its `card`
  or a window elsewhere taking the keyboard closes it. Exclusive keyboard only
  until it has it, or a window clicked on another monitor never got it.
  `Popover` (the control centre, the center, the power menu) is one that fades
  in and out, letting clicks and the keyboard go as it closes, then says
  `hidden`; reopened as it fades, it asks for the keyboard again.
- **`Card`** keeps the focused item whole in view in every list it is in, once
  keys have moved it. Tab and the arrows step through a ListView by index,
  making a row out of view (Qt's chain puts rows made while scrolling back
  last). Return and Space act once on a held key.
- **`ClickAway`**: a layer under the windows on every screen, taking input only
  while a panel is open, so bare desktop closes it.
- **`Screens`**: screens less Hyprland's `FALLBACK`, and the focused one.
- **`Command`**: a process whose failure (even to start) becomes a
  notification, or a log line while `quiet`; stopped and failed after
  `timeout` ms (10 s; 5 s for the shortcuts, 30 s past curl's own, 120 s for
  the clipboard's first decode, 0 for the package list), as each runs one at a
  time and a hung one would hold its feature for good; its stderr goes
  escaped and cut to its last 1000 characters. **`Deadline`** does the
  same for a bare `Process` (Caps Lock, Caffeine's state, night light, the VPN
  list), counted from each start, SIGKILL 2 s after its SIGTERM.
  **`StateFile`** writes nothing until its read is done or found no file
  (`ready`). **`Detached`**: one
  `systemd-run --user --scope` per app, since a service restart kills its
  cgroup; a program not on PATH is a critical notification instead. **`Watcher`**: a long-lived command started again as it stops,
  backing off until a run lasts a minute, with SIGPIPE back to its default
  (Quickshell's children inherit it ignored), so one a crashed shell left
  behind goes at its next line; nmcli, which ignores it itself, runs under a
  reader that takes it along. **`Time`** polls the clock each second rather
  than a `SystemClock`, which spins through a repeated DST hour. **`WheelSteps`**: whole notches,
  positive up, a touchpad's small steps adding up to them, a part notch
  dropped as the wheel turns back.
- **Nix in the QML** is only the `qs.nix` module in the store copy: `Colors`
  (the palette, translucent colours as Qt `#aarrggbb`), `Hyprsplit.workspaces`
  and `Symbols` (MDI 7.4 from `@mdi/svg`, `scripts/symbols.mjs` over
  `scripts/symbols.tsv`). So the shell runs from the built copy
  (`programs.quickshell.configs.shell`), not the checkout.
- **Tools by name from PATH** (`cliphist`, `wl-copy`, `pw-play`, `notify-send`,
  `xdg-open`, `systemd-run`, `hyprmoncfg`, `wezterm`, `awk`, `find`, `curl`, `nixpkgs-index`,
  `nixpkgs-run`, `hyprctl`, `systemctl`, `wpctl`, `camera-users`,
  `backlight-watch`, `nmcli`, `nm-connection-editor`, `brightnessctl`,
  `bluetui`, `pwvucontrol`, `qs`, systemd's `busctl` and util-linux's `setpriv`), so it works as any rice: an exception to store paths;
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
- `RectangularShadow` leaks an inner `ShaderEffect` per instance (Qt 6.11 and
  6.12, TODO.md): `Shadow` is a `ShaderEffect` on Qt's own shadow shader, whose
  `qrc:` file exists only once `QtQuick.Effects` is imported somewhere, so
  `Shadow` imports it itself.
- `ColorQuantizer` reads only local files (`QUrl::toLocalFile`), and an empty
  `source` keeps the last colours: `Media` downloads remote art first, and
  takes colours only for the file it asked about.
- Qt's pixmap cache keys a picture by URL, size, `fillMode` and the window's
  device pixel ratio: an `Image` kept to warm another's must match all of them
  (`Media`'s held cover).
- A QML `Timer` at interval 0 never fires: 1 is the next turn.
- A `ScriptModel` with `objectProp` mis-diffs rows rebuilt as new objects
  (TODO.md): a moved row keeps its old object, and from a row whose key matches
  but whose object differs it replaces row after row in place, so an insertion
  renames every row after it and appends one. Rows a binding rebuilds go
  through `common/keep.js`, which keeps each unchanged row the same object.
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
- Under `follow_mouse = 1` a window takes the keyboard from an `OnDemand`
  layer as the pointer only crosses it (Hyprland's `mouseMoveUnified`), and
  gives it back as the pointer comes onto the layer: a layer losing the
  keyboard is not a click elsewhere. Only `Exclusive` keeps it, clicks too.
- Qt opens a local file on the GUI thread, or with `asynchronous` on the
  engine's one pixmap reader thread, and `ColorQuantizer` waits for its last
  run on the GUI thread: a client's path (a FIFO, a hung mount) never reaches
  an `Image` or a quantizer, only a copy the shell made; a theme icon name
  with a slash is no icon.
- Quickshell emits `exited` before `runningChanged`: a process started again
  from its exit handler reads running throughout, so a binding on `running`
  never sees it end.
- A JsonAdapter property set in its singleton's `Component.onCompleted` fires
  no `adapterUpdated`, so it is never saved.
- NetworkManager's Update and AddConnection refuse a PSK outside 8–63 bytes
  (64 hex digits; SAE any), and Quickshell only logs it: Net checks before
  `connectWithPsk`, which takes only WPA and SAE networks.
- nmcli exits 143 itself on SIGTERM, a normal exit: a run its Deadline stopped
  is told by `expired`, not its exit status.
- V4 throws on `obj["__proto__"] = n`, and `constructor`, `toString` are
  there already: anything keyed by a client's string is a `Map`.

### Components: what the code does not say

- `launcher/`: one `LauncherWindow`, a `LauncherMode` per feature, each its own
  global shortcut (`quickshell:launcher-<name>`): SUPER+D `apps`, SUPER+V
  `clipboard`, SUPER+P `monitors`, SUPER+Tab `windows`, SUPER+N `nixpkgs`. A
  mode sets `rows` (unique `key`s keep delegates), `fields`, a `glyph` or
  `image`, optional `preview` and `find`. `search.js`: each word a substring,
  or a loose field's letters in order, or from four letters a word with one
  slip, ranked below; only a row's fields are marked. The card opens full
  height so it holds still while typing. A new query starts at its best
  match, even when it matches the same rows. `apps` ranks equal matches by `AppUsage` (log2 of the summed 2^weeks of
  each launch: a launch counts half as much a week later, and the stored number
  never needs decaying; an id whose use reads exactly 0, about a year
  unused, is dropped at the next launch) and warms every icon at start (an icon Papirus lacks costs thousands
  of stats). `clipboard` decodes each clip once into Quickshell's cache, pruned
  to what cliphist lists; it searches cliphist's preview, a clip's first 100
  characters (a picture's size and format too, never the counts under it); a
  clip is decoded to a file of its own before wl-copy takes it, so one that
  fails says so; each copy and delete is its own process; one listing per
  open serves the rows and the cache pass;
  cliphist with no database yet ("please store something first") is an empty
  history.
  Rows rebuilt under the same query (a retitled window, the counts) keep the
  selection by key; while its rows load a mode says nothing (`loading`). A mode with a preview keeps its pane, empty while nothing matches, so the card never changes shape under the keys. `monitors` lists the profile hyprmoncfgd would apply
  next first (`Recommended`), reloading a second after hotplug bursts.
  `windows` is wlr-foreign-toplevels in Hyprland focus order with live
  previews, none of a window whose size Hyprland has not given. `nixpkgs` searches nixos-unstable's ~130 000 packages
  (`nixpkgs-index` TSV, refreshed on every open through `systemd-run --scope`,
  outside the shell's memory limit; held as two strings, as read and lowered,
  with each line's start and name end in typed arrays, indexed a chunk a frame,
  so keys land meanwhile: ~80 MiB where a string per package took ~220 and kept
  ~95 after a release. A search scans the lowered string once per word, a
  line's first place only; a memo keyed on the ranks, no slip pass: it would
  cost a pass over every row per key. The strings and the file go a minute
  after the launcher closes, given back whole, and the next open reads the list
  again).
- `nixpkgs-run`: builds `github:NixOS/nixpkgs/<rev>#<attr>` with a progress card
  (`nixpkgs-progress.jq` over nix's internal-json), then runs it in a transient
  `systemd-run --user` service sandboxed by systemd: `ProtectSystem=strict`,
  `PrivateTmp`, tmpfs over `$HOME` and `$XDG_RUNTIME_DIR`, only PipeWire, X11
  and GTK/fontconfig/cursor settings bound back, no nix daemon, D-Bus or
  podman socket (the user is in `podman`, so rootful podman is root), and no
  `/dev/input`, `/dev/uinput` or `/dev/uhid` (reading or typing keys; a ZSA
  keyboard's raw HID still is, TODO.md); the GPU, cameras and `/dev/fuse` stay.
  Wayland through its own `security-context` socket, so Hyprland hides
  protocols that type into or capture other windows (X11 apps still share
  Xwayland). Desktop-entry programs run alone, others in wezterm, held open on
  failure or a run under 5 s.
- `shortcuts/` (SUPER+?): `hyprctl binds -j` per open; numbered and directional
  binds folded, media keys out (the config has no submaps); up to
  three balanced columns, shrunk only when none fits; it opens once the binds
  are read.
- `tooltip/`: the tooltip layer per screen (overlay, no input), drawn only while
  `Tooltips` shows one there; an app's text plain, at most a banner wide.
  From one tooltip the next shows at once (GTK's browse mode).
- `power/` (SUPER+X): five tiles, each key a keycap on it (pressed without Alt), Reload
  Hyprland, Restart to Firmware where logind's `CanRebootToFirmwareSetup` says
  so; ending the session or machine takes a second press within 5 s of the
  first, never a held key's repeat. The pointer moves the selection once it
  moves; actions run as a `Command`, so a refusal says so.
- `bar/`: per screen. Workspaces led by the distro's logo (`Machine`, 22 px in
  a workspace's square); other monitors' workspaces still
  here are named after them (`DP2-1`, `WorkspaceOwners`, remembering connectors
  across unplugs). Quickshell refreshes monitors only as one comes and drops
  windows opened on a workspace it has not loaded, so `Bar.qml` refreshes on
  those events and 300 ms after a burst. The status button, laid from its right edge, shows what records
  (`Privacy`), bell or Do Not Disturb, VPN, link, Bluetooth, a muted mic,
  volume, battery, a cup while Caffeine is on; the wheel steps the volume. The
  tray (`Tray`) shows its first three icons and "+N", and every icon while the
  pointer is in `BarWindow`'s right-end zone, which is the buttons' parent (hover
  reaches ancestors, not siblings beneath).
  `TrayMenu` (panel `tray-menu:SCREEN`) cascades as GTK's, takes the keyboard
  (Exclusive only until it has it, so a window clicked elsewhere gets it),
  closes a second after the pointer leaves (GTK's `MENU_POPDOWN_DELAY`; GTK
  itself waits for a click) unless keys drive it or the pointer comes back;
  losing the keyboard only lets go of the keys' hold, as a window the pointer
  crosses takes it (the pointer back on a card brings it back); Escape in
  a submenu goes back; a card is at most the screen, scrolling, its labels
  plain and elided.
- Caffeine (`controls/Caffeine.qml`, IPC `caffeine toggle|set|active`) is the
  `caffeine.service` user unit (`systemd-inhibit --what=idle`), so it outlives
  a shell restart.
- `weather/`: MET Norway for the time zone's city (`/etc/localtime` via
  `zone.tab`, no address lookup; a zone without coordinates is said once),
  every half hour and when a suspend skipped one. MET's terms: the forecast is
  cached (`weather.json` in the cache dir) with its Expires and
  Last-Modified, asked for again only once expired and only if modified; a
  failed fetch keeps the last. MET's icons fetched by `quickshell.nix`.
- `notifications/`: the daemon and popups. `Notifs` keeps each as a `NotifEntry`
  until dismissed, a second past close so views slide it away. Popups go to the
  monitor focused on arrival, five at most; over a fullscreen window only
  critical ones. Same card updates in place for a stack tag
  (`x-canonical-private-synchronous`, `x-dunst-stack-tag`), an id, or the same
  app, summary and body within 2 s; a stack tag is its app's own, and saved.
  Past 30 a second (critical apart) a flood is
  turned away and summed in one card, and an update in place (by id
  too) only updates its card (no reorder, popup or sound); text is cut before layout (a megabyte held
  the shell for seconds); newest three per app, 100 in all. Body markup filtered
  to the spec (`markup.js`). elementary OS sounds via `pw-play`, one per 300 ms,
  none past 30 s; a client's `sound-file` only if it is a plain file under
  10 MB (never a pipe or a device), ours otherwise.
  A banner never expands: a click runs its default action, else its one
  button, else puts it away; a right click dismisses it (the user's, over the
  HIG); the pointer on it holds its timeout; it goes as it came. An update closed in the same turn is not put back.
  `History` saves atomically to the state dir (no transient ones, 7 days,
  `history.js`), with every picture copied into the cache dir: a client's
  file by a process (a plain file of up to 10 MB, read under a 2 s timeout),
  as only the copy is drawn and saved; one only the server held grabbed off
  screen once in a window of their own (`PictureCopies`, a 1 px overlay on
  the first screen, moved rather than destroyed as monitors go; a grab waits
  for a monitor, and one its window took down is made again); a prune spares
  pictures newer than its list and those of live notifications. App names
  key `Map`s, so `__proto__` is just a name. `Notifs` is read at start, so
  the server runs with no monitor on. IPC `notifications toggleDnd|setDnd|dnd|count|clear|hidePopups`.
- `center/`: GNOME's date menu under the clock, one per screen (`center:DP-1`): `Media`'s
  player's `MediaCard`, notifications grouped per app, calendar (ISO weeks) and weather
  where there is room. Opening it checks all, puts popups away and sorts the
  groups; while open a group keeps its place as its notifications go, a new app
  comes in on top. Clear slides every group in view off at once (each its own
  swipe) and dismisses the rest unanimated, no Undo; a card whose group gained
  one mid-slide comes back. Collapse All also shuts each card's More. A click
  runs a lone card's default action; its arrow (a button) expands it; a right
  click dismisses a card or group. The list's wheel glides, but over the media
  card the card's own wheel goes first. Do Not Disturb is a switch in its
  footer.
- `controls/` (SUPER+A): GNOME's quick settings: `Header` (the battery, or
  without one the machine), `Levels` (the volume, its arrow
  opening Sound: Output and Input, a symbol per device from its PipeWire
  properties, `devices.js`, and Audio Settings (pwvucontrol, whose meters
  Privacy already skips as passive); no mic mute; dim but for the arrow
  with a microphone and no output; each backlight), the `Pill`s
  the machine has (`Controls.toggles`), a `Menu` under the row that opens it (one slot
  per row, so its menus swap in place at once, the slot easing to the new
  height; a menu fades as its slot eases open or shut, the user's pick over
  GNOME's two steps; one moving to another row eases shut as fast as the other opens,
  so the card moves one way; a new menu comes at its full height, rows arriving
  only once it is drawn; rows keep the order they came in while it is open),
  `InUse` (`Pill`s raising the app's window) while something records. Backends are singletons: `Net`
  (Quickshell.Networking for Wi-Fi and wired, every Wi-Fi card's networks,
  under each card's name where there are several, as GNOME's; a hidden network
  by name: `nmcli connection add` a profile marked hidden, the password then
  over D-Bus (`connectWithPsk`), never on a command line, the profile gone
  again if it never connects; a WPA key NetworkManager would refuse is
  refused in the prompt; WEP and other keys `connectWithPsk` cannot take go
  to `nm-connection-editor`; `nmcli` for VPNs; a captive
  portal gets a card; Wi-Fi without internet offers Sign In too, as a portal
  blocking DoT reads as limited: `nmcli device modify` gives the connection,
  not the profile, DHCP DNS without TLS, `device reapply` once online), `BluetoothDevices` (pair, trust, connect in one click; a
  PIN device goes to bluetui), `Volume`, `Microphone`, `NightLight`
  (hyprsunset, state kept and restored when hyprsunset restarts), `Media`
  (the card's player: the last to start, once it has played 1.5 s, so a
  YouTube hover preview never takes it; the shown one kept 2 s after it pauses
  or stops, then the card goes back to the newest still playing, else stays
  on it, paused. With two or three players playing or paused the card has
  a button each in arrival order, and a click pins that one: it holds while
  its player plays, and goes when it is clicked again, the choice goes (one
  player, or a fourth), or its player has stopped playing and another plays.
  The wheel on the card steps through them, pinning each, round and back; on
  its seek bar it seeks. A title or artist cut short slides to its end and
  back while the pointer is on the card.
  The card is the cover's colour, `Theme.cover` over `ColorQuantizer`'s eight:
  OKLab 0.40, the seek bar and play button 0.84, white on a grey cover; the
  art square, or as wide as 16:9 for a video's thumbnail. Art is
  read from a copy in the cache dir (a local file copied anew under `timeout`
  and 20 MB, so a FIFO or a device holds nothing up and a deleted cover never
  makes Qt warn), from the start rather than as the center opens:
  remote art downloaded to the cache dir in the background, kept by URL (the
  last 32, pictures only), and held decoded so the card has it at once),
  `Power` (UPower display device), `Privacy` (a capture stream from a mic while
  audio flows, meters and passive filters aside; any `Video/Source` without a `device.api` (a portal's screen cast, or another); a camera
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
  level at its end still shows. The microphone shows only as it is muted (a
  call's gain moves its level all the while); the mute key also dispatches
  `quickshell:osd-microphone`, read through `wpctl`, so a virtual input shows
  too. A Bluetooth headset switching profile is the same output. The volume
  key raises to 100 % and never pulls a level past it back down.

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
  failing on any warning, unused imports too (`--json`, as text output drops
  some). It writes the
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
  item, a `MouseArea` naming no cursor, a plain space between number and unit,
  an animation with no easing, a `Text` bound to an outside string (an app's
  name, a title) without `textFormat` (markup could load a URL).
  Deliberate exceptions are listed in the script with why.
- `notification-markup`, `notification-history`, `launcher-search`, `names`,
  `sound-devices`, `keep`, `cover`, `wheel-steps`: `qmltestrunner` over
  `tests/tst_{markup,history,search,names,devices,keep,cover,wheel}.qml`, each with
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
qst hold p 1500                # held down, so the client repeats it
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
qst tray                       # a tray item with nested submenus; `tray log`, `tray add first 4` (`tray add long 1 80`: a menu 80 entries long), `tray remove first`, `tray clear`
qst x notify-send -a Discord loft01 hello   # anything inside the session
qst pipewire restart           # or stop, start
qst backlight intel_backlight 40 [MAX]      # fake backlight; `NAME remove`
qst camera open zoom [video1]  # `close zoom`, `add video1 [locked]`, `unlock video1`, `remove video0`
qst network wifi add Cafe 40 open # the fake NetworkManager: wifi add SSID [STRENGTH] [SECURITY] [PASSWORD], wifi remove|hide|strength|clear,
                               # wifi many 300 [PREFIX], wifi json JSON, device add|remove NAME [wifi|ethernet], cable NAME on|off,
                               # profile wifi|ethernet|wireguard|vpn NAME [SSID PSK], vpn NAME ok|fail|secrets, up NAME,
                               # connectivity none|portal|limited|full, switch on|off, delay MS, lag MS (a new profile offered that late), dump, stop|start|restart, kill (mid-call, back fresh)
qst battery 15 discharging 1800             # PERCENT [charging|discharging|full|pending [SECONDS]], or remove
qst bluetooth add 11:22:33:44:55:01 Headset audio-headset ok paired connected 70   # behaviour ok, pin, fail, slow (a connect taking 1.5 s) or crowded; `bluetooth kill` mid-call
qst player add spotify Spotify Playing [ART] [JSON]   # MPRIS, ART a file or a URL, JSON more of tests/mpris.py's parameters; status NAME STATE, track NAME TITLE [ARTIST], remove NAME, clear
qst upower stop                # or start; `logind stop|start [ANSWER]`, `wireplumber stop|start` (PipeWire stays up)
qst hole org.bluez system      # a name held by something that takes every call and answers none; `hole NAME off`
qst kill SEGV                  # a crash, waiting for Quickshell's relaunch in place; `kill` (KILL) takes the helpers too, then `qst restart`
QS_TEST_CLOCK=1 qst case "…"   # the shell on libfaketime (and the system malloc: jemalloc deadlocks under it)
qst clock +8h                  # its clock that far from the machine's; `clock -1h`, `clock at "2027-03-28 00:59:50 UTC"`
qst suspend +8h [SECONDS]      # the shell and its helpers frozen SECONDS (1.1) while its clock moves on 8 h: a suspend as it lives one
QS_TEST_DISK=256k qst case "…" # its state and cache on tmpfs that small, in a mount namespace of its own
qst disk fill                  # those filled to the last byte; `disk free`, `disk CMD…` run where the shell sees them
qst fuzz 400 [SEED]            # random panels, keys, clicks, wheel, notifications, idle calls, hotplugs; invariants 130 ms after each; prints its seed
qst sync                       # copy edited QML in, restart qs, print warnings
qst problems                   # warnings less tests/known-warnings and this case's expects
qst census                     # what the probe finds wrong on screen
qst areas [REGEX]              # mouse areas: x, y, label, enabled, clicks, hand
qst cursor 960 21 [hand]       # the cursor Qt sets there
qst cursors [WINDOW]           # every clickable area asks for a hand
qst motion start               # record items per frame; `motion stop` fails on a jump
qst fail cliphist exit         # or crash, missing, garbage, hang, slow (3 s), truncated, huge (20 MB more), lie (then exit 1), 'say=[]'; `fail cliphist off`
qst fail hyprctl hang 'binds*' # only the calls whose arguments match the glob, the rest as before
qst expect [--may] 'hyprmoncfg'   # this case must (or may) log a warning matching it
qst actions                    # what the session tried to run on the machine
qst lint                       # the qmllint check on the checkout
qst down                       # kill and delete the session(s) and the test shell's state
```

### The session's fakes

- `systemctl`, `loginctl`, `pw-play`, `xdg-open`, `nixpkgs-run`, `brightnessctl`, `curl`, `nixpkgs-index`
  and `hyprmoncfg` log to `qst actions` (`hyprmoncfg status` answers
  `tests/hyprmoncfg/status.json`, the desktop's profiles from
  `hosts/desktop/monitors.nix`, copied into `$QS_TEST_DIR/cfg/hyprmoncfg/profiles`). `curl`
  answers MET Norway with twelve hours from now, expiring in an hour and
  unmodified to If-Modified-Since (each case drops the cached forecast);
  `nixpkgs-index` writes a handful of packages once per session. No case
  reaches the network.
  `systemd-run --scope` logs and runs in the session (only logs while
  `$QS_TEST_DIR/no-launch` exists, as during `fuzz`). `hyprctl` is the test
  Hyprland's, `hl.dsp.exit()` only logged. cliphist has a database of the
  session's own, none at the start of a case, never the user's clips.
  `systemctl --user start|stop|is-active` keeps state in `$QS_TEST_DIR/units`.
- Config dir: the user's, symlinked, except `hypr/` and `hyprmoncfg/`.
- qs at `QT_SCALE_FACTOR` 1 unless `QS_TEST_SCALE`, with `TZDIR` (Qt needs it
  on NixOS), `QS_PIPEWIRE_IMMEDIATE_RECONNECT` as the unit, and its state and
  cache in `$QS_TEST_DIR/state` and `cache` (a case may lock them; reset
  unlocks and empties them). `TZ`, `LC_ALL` set on `qst case` reach it.
  Everything it starts carries `QS_TEST_SHELL=$QS_TEST_DIR`, by which a case
  counts its watchers and `stop_qs` kills what outlived the group (a crash
  reporter, helpers left by a relaunch). `bar fakeOutputs 1000` fakes 1000 outputs; `realVolume` drops them;
  `probe chain FIRST THEN` runs THEN from FIRST's exit in one `Command`,
  `probe launch PROGRAM` launches as the shell does (the probe's IPC, not
  the live shell's).
- System bus: python-dbusmock templates via `qs-dbusmock`, fresh per case:
  NetworkManager (`tests/networkmanager.py`; wired + wg0 up, three networks,
  unless `QS_TEST_NETWORK=none`; a hidden profile is there on every card and
  probed for, failing as not found, as NetworkManager's; Update and
  AddConnection refuse a WPA key as its `verify_secrets` does: 8–63 bytes or
  64 hex digits, SAE any), UPower (`tests/upower.py`; battery 76 %
  discharging), BlueZ (`tests/bluez.py`; an adapter, unless
  `QS_TEST_BLUETOOTH=none`), logind (`tests/logind.py`; only
  `CanRebootToFirmwareSetup`, yes). `nmcli` is real except `connection up`, which asks
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
  The brightness keys run the host's brightnessctl, which cannot write the
  real backlight's sysfs and asks the mock logind, which has no
  `SetBrightness`, so they change nothing: drive `quickshell:osd-brightness`
  and `qst backlight` instead.
  The volume keys reach the session's PipeWire.
- hyprsunset runs in the session.

### Session notes

- `sync` copies files and restarts qs (a hot reload keeps inline components'
  old types); it and `restart` return once the bars are up, as the shell makes
  its windows only after `qs list`. `reset` does not re-copy. A palette, `Symbols` or Hyprland config
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
  process group (its inotify watchers outlive it otherwise). A pid from a file
  is signalled only while `/proc/PID/environ` carries this session's
  `XDG_RUNTIME_DIR`, and `up` after a session whose Hyprland died sweeps what
  is left of it as `down` does.
- The session bus starts with the session's environment, never the live
  display, signature or buses; once Hyprland is up, `up` hands it Hyprland's
  display and signature (`dbus-update-activation-environment`, never
  `--systemd`), so the portals, gvfs and dconf it activates reach the test
  compositor. They run without PipeWire realtime (`PIPEWIRE_CONFIG_DIR` with
  `module.rt = false`): the portal asks its own Realtime interface as it
  reconnects after each reset, and stalled 25 s per call.
- `reset` clears qs-input's locked modifiers, so a Caps Lock never carries
  into the next case; a session up from before a harness change to qs-input
  needs `down`.
- Each `qst` is a `writeShellApplication` whose PATH puts real tools ahead;
  `enter` puts the session's `bin/` back in front.
- Shots: the cursor a surface asked for shows only after the pointer moves over
  it once mapped; thin grey lines are headless-output artifacts. Animation:
  `qst motion`, or background `qst x grim -s 0.25` ~35 ms apart and `md5sum`.
- `notify-send -A` waits: background it. Tray menus close on a click elsewhere,
  their icon, or Escape.
- `QS_TEST_COLD=1 qst case` resets without the probe, whose read creates every
  singleton: a case of what a shell nobody has looked at does.

### State and scenarios

`qst state` is `tests/Probe.qml` (IPC target `probe`, only in the session's
copy; a snapshot reads it over `probe.sock` with curl, a third of a `qs ipc`
process's cost, until the socket is up): panel, screens and monitors, workspaces, windows, popups, notification
history (with `body`), DND and `dndFlips`, volume, microphone, OSD, brightness,
caps, privacy, the status button's glyphs (and `opaque`, those drawn whole),
`notificationPictures` (images loaded in the popups and the center), `clocks` (screens whose clock shows its center open),
controls and its backends, tray, tray menu, the focused
control (`focused`, its row's `focusedTitle`) and `ring`, `hovered` (pieces lit by the pointer), tooltip, sliders,
launcher `results` and `selected` (by key), `weather`, `center` (groups with `y`, `slid`) and `centerMore`,
`machine`, `field`, `problems`, `layers`, `hypr`. A field a
test needs goes in the probe, read through the shell's own singletons.

Every snapshot also checks the whole shell:

- `problems` (the census): text with no room, a one-line label broken over
  lines, lines past their box or cut by a clip (a list's past its view and
  content), or under 8 pt, contrast below 3:1
  (Theme's faint colour and fading text aside), colours and radii not Theme's
  (the media card's `Media.tint` counts as Theme's; a running `Behavior on
  color` is held to its target),
  images without source, failing or loading past 5 s, a disabled area setting a
  hand, a card off its window, text over text, `undefined`, `NaN`,
  `[object` or `Invalid Date` in a label, a window that is not a layer surface.
- `invariants` (`tests/invariants.jq`): the open panel is one the shell has,
  on a screen that is there, with its layer on that screen (the shortcuts may
  wait up to 5 s for Hyprland's binds), and vice versa, one layer per panel;
  every screen one bar, click-away and notifications layer; the dim on every
  screen or none; a tooltip layer exactly while a tooltip shows; the shell's
  screens Hyprland's enabled monitors by name and id; nothing on `FALLBACK`,
  popups only on real screens and five at most, three per app past the popped
  up, history within 100; the status button's cup, bell, Do Not Disturb and
  microphone as their backends say, the clocks pressed as the center open,
  no slider without a value; a probe answer within 2 s, a countdown never
  going back up.

`wait`/`stays` fail on a problem lasting 500 ms (a transition passes through
some), and at once on the countdown. A case fails on any warning qs logs, less
`tests/known-warnings` (regex, tab, why) and its own `expect`s; on qs peaking
past `QS_TEST_PEAK` MiB (1024, `VmHWM`); on two of a watcher (`camera-users`,
`nmcli monitor`, backlight-watch's `udevadm`) at once; on qs gone unless the
case killed it (`qst kill`); on an `IpcHandler` in the source that isn't
registered. An empty `expect` or known-warnings line is refused (it would allow
every line), and so is a pattern grep cannot read or one matching an empty
line; a failed filter fails `problems` rather than hiding every warning. A
whole green `run` names the known warnings no case met, which can go.

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
| `binds.sh` | every global bind opens its own panel and closes it, held down too |
| `caffeine.sh` | Caffeine's unit, pill and status cup, a cold shell's IPC |
| `chaos.sh` | hostile and broken clients: floods, megabytes of text, bad icons, panel and hotplug storms, 40-window workspaces, 60 outputs, damaged state, 200 tray items, 300 hostile network names, 1000 outputs, 50 VPNs, 100 BT devices, 30 players, small and 4K screens, the shell stopped 10 s under a flood, services and a notification server that hold their names and never answer, NetworkManager and BlueZ killed mid-call, a second shell run by hand, apps named `__proto__` |
| `clock.sh` | the wall clock moved under the shell: a suspend's gap, the shell frozen through one, set back, midnight, both clock changes, the uptime under a moved clock |
| `controls.sh` | the control centre: open/close paths, status glyphs, header (battery or machine), every pill and menu against the fakes, a password tried as the centre shuts, two VPNs at once, a failed connect mid-scan, hidden networks (one named as one in view, joined late), WPA keys NetworkManager refuses, WEP, a sign-in dropped and joined again, a hung VPN list, two Wi-Fi cards, the sound menu's headings, symbols and Audio Settings, services stopping under it, PipeWire absent at start, WirePlumber dying alone, Return on a sound output, the player the center's card shows, its buttons and pin, the cover's colour, a cover that is a FIFO, barely-players |
| `cursors.sh` | the bar and every panel's cursors, a closed hand mid-drag |
| `design.sh` | every surface on screen, scaled too, in three other locales, for the census |
| `failures.sh` | the shell's tools failing, hanging, slow, cut short, enormous (`qst fail`), the cached forecast, the shell crashed and killed, its state and cache locked, a full disk, a command's error as written, an app not installed |
| `history.sh` | saved history across restarts and in-place reloads, kept pictures, damaged files, a picture arriving with no monitor on, a file's copy outliving it, pipes in a saved history |
| `hotplug.sh` | unplug, disable, replug under every panel, menus and popups; the center per screen; the server with no monitor at start; panels for absent screens; a portrait screen at a negative origin; Hyprland reloading |
| `idle.sh` | the idle dim under `motion`, clicks through it, the lock command's holds, a hold whose lock never comes |
| `interactions.sh` | fixes that had no case: popups, wheel past 100 %, clip scope, 1024x600 and 1080p at scale 3, power keys (held, rearmed, firmware), a banner's click, hover after a panel closes, a drag let go outside the centre, Space held on a switch, a long menu by keys, a process run again from its exit, a status glyph back mid-fade |
| `launcher.sh` | typing as it opens, open time, clicks on another monitor, nixpkgs search at full size and on a broken list, the selection under a retitling window, the clipboard's counts, Return twice |
| `motion.sh` | center groups expanding, the OSD fading, toggle menus handed between and within rows |
| `notifications.sh` | per-app limits, five popups, stack tags, DND, the bell, flood sounds, bare-path pictures, Clear, groups holding their places, Collapse All shutting More, a hovered banner, updates by id (closed at once, past the flood limit), markup in labels, hostile hints, pictures and app icons that are pipes, paths with a space, # and %, an app icon naming another's picture |
| `osd.sh` | what shows and what must not (a mic level moving, the volume key past 100 %) |
| `privacy.sh` | mics real and virtual, casts, cameras via PipeWire and `/dev`, an app named over several lines |
| `soak.sh` | one shell used for long: `fuzz`, every panel fifty times (memory, open files), idle CPU, the package list's memory given back |
| `tray.sh` | the tray strip, its menus and keys, Escape in a submenu, an opener hovered back onto, a pointer slipping off and back, onto a window too, the keyboard back to a window, a tray menu named over IPC |
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
- In jq a pipe binds looser than `==` and a comma looser still:
  `(.popups | map(.screen)) == [...]`, `[(a | max), (b | max)]`.

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
    thresholds, UPower, disko (ext4, LVM off), `treefmt`; for Chromecast 5353 and, for 10 s, the
    port an outgoing mDNS or SSDP query left from (nftables set `discovery`).
  - `desktop`: `base workstation gaming moonshine`; AMD, RX 6700 XT, ZSA udev
    rules, disko (ext4, LVM off), hyprmoncfg profiles `default`/`left-only`/`right-only`,
    nix-index, startup apps pinned to monitors, `quickshell.scale = 1.2`.
- **Profiles**: `base` (nixos: `boot doas documentation git home-manager
  journald locale network neovim nix nixpkgs packages podman unstable-nixpkgs
  users`; HM: `git pi-agent tmux users xdg-user-dirs zsh`), `workstation`
  (nixos: `display-manager fonts gtk hyprland nautilus plymouth sound`; HM:
  `bluetooth cursor desktop-apps gtk hyprland nautilus neovim qt wezterm`). The NixOS half pulls in
  the HM half.
- **Theme** (`modules/theme/`): `palette.nix` declares `palettes`; `fonts`
  nixos, `gtk` both, `cursor` and `qt` HM. GTK4 recoloured through libadwaita's
  `:root` variables (dark only), GTK3 through adw-gtk3's `@define-color`, both
  in the user `gtk.css`; Qt's adwaita-dark keeps its own.
