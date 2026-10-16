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
  aspect itself (home-manager `piAgent.settings`, `neovim.outOfStorePath`) and
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
- **Keep comments minimal.** Comment the *why*, not the *what*. One line.
- Don't add a flake-parts dependency or reintroduce `specialArgs` plumbing.

## Repo map

```
flake.nix                 entry point: evalModules { class = "flake"; ... }
import-tree.nix           dir -> module that imports every .nix beneath it
flake.lock                pinned inputs
README.md                 brief user-facing doc
AGENTS.md                 this file

modules/flake/            the substrate (see below)
modules/features/         one flat file per feature (+ hyprland/, neovim/, pi-agent/)
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
is pruned with `follows = ""`) and `hyprsplit` (its `nixpkgs` follows
`hyprland/nixpkgs`, which is what it builds with anyway).

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
  _class = class;                              # nixos | homeManager
  _file = "flake.modules.${class}.${name}";
  imports = [ module ];
}
```

The `_class` tag makes loading a home-manager module into a NixOS
configuration a plain type error instead of "undeclared option" noise. The
`_file` tag gives readable error locations.

The registry is exported verbatim as the flake output `modules`
(hence Nix's harmless `unknown flake output 'modules'` warning), which is what
makes `inputs.nixdots.modules.homeManager.<aspect>` work from another flake.
The values a stored aspect reads from `root.config` are this flake's; an
importer changes behaviour through the aspect's own options or `lib.mkForce`.

### Top-level options

| Option | Type | Notes |
| --- | --- | --- |
| `identity` | `{ username, fullName, email }` | Primary user; read by `users`, `git`, `home-manager`, profiles. |
| `palettes` | `attrsOf (attrsOf str)` | `ui` (rofi, mako, waybar, hyprland, hyprlock), `adwaita_dark` (wezterm), `kanagawa` (tmux). |
| `hyprland.workspaces` | positive int | Workspaces per monitor; read by hyprsplit's config, the binds and waybar's labels. |
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
| `boot.nix` | nixos | `boot`, `systemd-boot` | GRUB-on-EFI default (theme via `runCommand`); `systemd-boot` aspect `mkForce`s GRUB off |
| `desktop-apps.nix` | homeManager | `desktop-apps` | GUI apps every workstation gets (browsers, spotify, obsidian, discord, …) |
| `display-manager.nix` | nixos | `display-manager` | ly |
| `doas.nix` | nixos | `doas` | doas replaces sudo (via `doas-sudo-shim`), wheel `noPass` without `keepenv`, passing only `LANG` and `NIX_PATH` |
| `documentation.nix` | nixos | `documentation` | disables NixOS manpages |
| `gaming.nix` | nixos | `gaming` | Steam + proton-ge (Steam also sets 32-bit graphics) |
| `git.nix` | nixos, homeManager | `git` | git on; user identity from `identity` |
| `home-manager.nix` | nixos | `home-manager` | wires HM for `identity.username`, `useGlobalPkgs`/`useUserPackages`, `backupFileExtension = "hm-bak"`; pulls `nixosConfigurations/<hostname>/home` |
| `hyprland/` | nixos, homeManager | `hyprland` (+ top-level `hyprland.workspaces`) | see below |
| `homelab.nix` | homeManager | `homelab` | `just` + `helm`, `KUBECONFIG=~/.kube/loft01`, and an ssh `loft01` host (10.0.0.1) that forwards local 6443 to the k3s API |
| `incus.nix` | nixos | `incus` | incus + preseed bridge/profile/storage |
| `journald.nix` | nixos | `journald` | 90-day retention |
| `libvirt.nix` | nixos | `libvirt` | libvirtd + unprivileged QEMU/KVM with swtpm, virt-manager, trusted `br0` lab bridge |
| `locale.nix` | nixos | `locale` | `no`/`nodeadkeys`, `en_DK.UTF-8`, Europe/Oslo, timesyncd; hyprland reads the xkb values via `osConfig` |
| `neovim/` | nixos, homeManager | `neovim` (+ HM option `neovim.outOfStorePath`) | see below |
| `network.nix` | nixos | `network` | systemd-resolved + DoT/DNSSEC, NetworkManager, nftables, reverse-path filter `loose` (WireGuard full tunnels) |
| `nix.nix` | nixos | `nix` | GC, `auto-optimise-store`, flakes, cache, no global registry; the `nixpkgs` registry entry and `NIX_PATH` come from nixpkgs' own `nixpkgs.flake.source` |
| `nix-index.nix` | homeManager | `nix-index` | small prebuilt nix-index DB (`nix-index-database` input) + wrapped comma, no full-DB cache symlink |
| `nixpkgs.nix` | nixos | `nixpkgs`, `unstable-nixpkgs` | `allowUnfree`; overlay exposing `pkgs.unstable` |
| `packages.nix` | nixos | `packages` | jq, fzf, fastfetch, tree, kubectl |
| `pi-agent/` | homeManager | `pi-agent` (+ HM option `piAgent.settings`) | [pi](https://pi.dev) from `nixpkgs-unstable`, plus its `~/.pi/agent` settings, `APPEND_SYSTEM.md` and skills |
| `plymouth.nix` | nixos | `plymouth` | plymouth + quiet boot params |
| `podman.nix` | nixos | `podman` | podman + docker compat, DNS on `podman0` |
| `rofi.nix` | homeManager | `rofi` | rofi theme generated from `palettes.ui` |
| `sound.nix` | nixos | `sound` | pipewire + rtkit |
| `tmux.nix` | homeManager | `tmux` | `programs.tmux` (socket under `$XDG_RUNTIME_DIR` on Linux) + own keymap, status from `palettes.kanagawa` |
| `users.nix` | nixos, homeManager | `users` | primary user, groups, hashed password, zsh (no global compinit; oh-my-zsh runs it) + starship, root locked |
| `wezterm.nix` | homeManager | `wezterm` | wezterm with an "Adwaita Dark" scheme from `palettes.adwaita_dark`, Hack font |
| `xdg.nix` | homeManager | `xdg-user-dirs` | XDG user dirs (created; projects = HM default `~/Projects`) |
| `zsh.nix` | homeManager | `zsh` | oh-my-zsh, autosuggestions, syntax highlight, 100k history, `programs.fzf` keybindings (Ctrl-R/Ctrl-T/Alt-C) |

Notes on specific features:

- **`hyprland/`** is split across `default.nix` (nixos + HM base),
  `bindings.nix`, `rules.nix`, `mako.nix`, `waybar.nix`, `hypridle.nix`,
  `hyprlock.nix`, `plugins.nix`, plus `assets/` and `scripts/`. It uses the
  pinned Hyprland input and its **Lua-based settings API** — binds and
  events are built with `lib.generators.mkLuaInline` and `_args` rather than
  the classic string config; `bindings.nix` has a `mkBind` helper and generates
  the workspace, direction and XF86 media/brightness binds.
  - `plugins.nix` declares `hyprland.workspaces` and loads the `hyprsplit` Lua
    library as the local `hs`; workspace binds use `hs.dsp.focus` /
    `hs.dsp.window.move`. hyprsplit numbers monitor *k*'s workspaces
    `k*n+1 … (k+1)*n`, so waybar's `format-icons` maps them back to `1 … n`.
  - Session daemons are home-manager user services bound to
    `hyprland-session.target` through `wayland.systemd.target`, so they never
    start under another compositor: waybar, cliphist, kanshi, hypridle,
    hyprpolkitagent and nm-applet (whose unit hardcodes
    `graphical-session.target`, hence a `mkForce`). mako is D-Bus activated.
  - With kanshi enabled, `config.reloaded` runs `kanshictl reload`, because a
    Hyprland reload re-applies its own monitor rules.
  - hyprlock talks to fprintd itself (`auth:fingerprint`, on when
    `services.fprintd` is), so the NixOS half turns `fprintAuth` off for
    hyprlock's PAM service.
  - The screenshot binds call one `writeShellApplication` (`scripts/freeze-region.sh`,
    `copy|save`) that carries its own runtime inputs.
  - Binds reference configured packages (`config.programs.wezterm.package`,
    `config.programs.rofi.finalPackage`, …) rather than `pkgs.*`.
  - The HM half reads `osConfig` (compositor package, xkb layout, fprintd,
    NetworkManager), so it requires the NixOS half.
- **`neovim/`** ships a Lua config in-tree. `homeManager.neovim` symlinks
  `xdg.configFile."nvim".source` to the module dir, or to the home-manager
  option `neovim.outOfStorePath` (a checkout) for live editing. git (for
  `vim.pack`), LSP servers, formatters, `gcc`, `tree-sitter` and `fzf` are
  `programs.neovim.extraPackages`,
  so they are on nvim's PATH only; ripgrep and fd come from `programs.ripgrep` /
  `programs.fd` for the shell too. Per-server LSP overrides live in `after/lsp/`.
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
  project shell's versions win. It writes `settings.json`, `APPEND_SYSTEM.md`
  and the `commit-style` skill into `~/.pi/agent` (pi ignores XDG), merging its
  home-manager option `piAgent.settings` over the defaults; both hosts set it
  to pin their provider, model and thinking level. The defaults exclude
  herdr's auto-discovered `extensions/herdr-*` integration. pi packages
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
  hyprland neovim qt rofi wezterm`. Its NixOS half pulls in the HM half.

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

- **`thonkpad`** — imports `base workstation gaming`. Imports the `homelab` home aspect. Intel laptop:
  microcode, firmware, bluetooth, graphics + `intel-media-driver`, fstrim, fwupd, zram, `fprintd`,
  `thermald`, TLP battery thresholds, disko, single-monitor kanshi profile,
  `treefmt`.
- **`desktop`** — imports `base workstation gaming incus libvirt`. Imports the `homelab` home aspect. AMD desktop:
  microcode, firmware, RX 6700 XT graphics, `kvm-amd`, fstrim, fwupd, zram, ZSA keyboard udev rules
  (keymapp), disko, two-monitor kanshi
  profile, trusted `m3lab0`, nix-index, `programs.gh` (git credential helper
  for github.com), quickshell, `piAgent` settings, SSH match blocks,
  host-specific app list.

## External consumers

The mac (a separate nix-darwin flake) imports `modules.homeManager.{wezterm,
neovim, pi-agent, tmux}`. Keep those aspects platform-neutral (no
Linux-only packages without a guard), and expose anything the mac must set as
an option of the aspect.

## Build, check, format

```bash
host=thonkpad

sudo nixos-rebuild switch --flake ".#$host"
nix build ".#nixosConfigurations.$host.config.system.build.toplevel"

nix build ".#nixosConfigurations.offlineInstaller-$host.config.system.build.isoImage"

nix flake check          # runs both checks below
nix fmt                  # formatter = nixfmt-tree
```

`modules/flake/checks.nix` defines, via `perSystem`:

- `checks.<system>.format` — runs `nixfmt --check` over every `.nix` in the
  repo. Keep the tree `nixfmt`-clean.
- `checks.<system>.eval` (Linux systems only) — instantiates
  `system.config.system.build.toplevel.drvPath` for every NixOS host and
  installer, forcing the whole derivation graph without building it (the
  string context is discarded).

`nix flake check` skips `aarch64-darwin` unless `--all-systems`.

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
  `mkForce`s GRUB off; a host adds it on top of `base`.
- **The `modules` flake output is not a standard output.** Nix warns about it;
  it is intentional and required for external imports.
- **`programs.ssh.matchBlocks` is deprecated** in `modules/hosts/desktop/home.nix`;
  migrate to `programs.ssh.settings` when touching it.
- **Two nixpkgs channels.** Default `pkgs` comes from `nixpkgs`;
  `pkgs.unstable` comes from the `unstable-nixpkgs` overlay. Prefer the
  default unless a package needs unstable.
- **Never hardcode the username.** Read `config.identity.username`.
