# AGENTS.md

Technical reference for agents working in this repo. The user-facing
quickstart and external import guide is in [README.md](./README.md).

## What this is

One flake holding all of `leier`'s NixOS, nix-darwin and home-manager
configurations, written in the [dendritic
pattern](https://github.com/mightyiam/dendritic): there is a single top-level
`lib.evalModules` evaluation, and *every* module of every class is a value of
it. There is no flake-parts dependency; the substrate is hand-rolled in
`flake.nix`, `import-tree.nix` and `modules/flake/`.

## Non-negotiables

- **A file is a feature.** One `.nix` file under `modules/features/` describes
  every class it touches (`nixos`, `homeManager`, `darwin`). No
  side files per class.
- **Share values through the top-level configuration, never `specialArgs`.**
  Cross-cutting data lives in a declared option (`identity`, `palettes`,
  `piAgent.settings`, `neovim.outOfStorePath`) and is read as
  `root.config.<option>`. This is the dendritic substitute for importing
  sibling files.
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
modules/features/         one flat file per feature (+ hyprland/, neovim/)
modules/profiles/         base.nix, workstation.nix
modules/theme/            palette.nix, fonts, gtk, qt, cursor
modules/hosts/            desktop/, thonkpad/
```

## The substrate

### `flake.nix`

```nix
outputs = inputs:
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
  _class = class;                              # nixos | homeManager | darwin
  _file = "flake.modules.${class}.${name}";
  imports = [ module ];
}
```

The `_class` tag makes loading a home-manager module into a NixOS
configuration a plain type error instead of "undeclared option" noise. The
`_file` tag gives readable error locations.

The registry is exported verbatim as the flake output `modules`
(hence Nix's harmless `unknown flake output 'modules'` warning), which is what
makes `inputs.nixdots.modules.nixos.<aspect>` work from another flake.

### Top-level options

| Option | Type | Notes |
| --- | --- | --- |
| `identity` | `{ username, fullName, email }` | Primary user; read by `users`, `git`, `home-manager`, profiles. |
| `palettes` | `attrsOf (attrsOf str)` | `ui` (rofi, mako, waybar), `adwaitaDarker` (kitty), `kanagawa` (tmux). |
| `nixosHosts.<name>` | submodule `{ system }` | Drives `flake.nixosConfigurations`. |
| `darwinHosts.<name>` | submodule `{ system }` | Drives `flake.darwinConfigurations`. |
| `homeConfigs.<name>` | submodule `{ system }` | Standalone HM for non-NixOS machines. |
| `systems` | `listOf str` | Default `[ "x86_64-linux" "aarch64-darwin" ]`. Drives `perSystem`. |
| `perSystem` | `deferredModule` | Evaluated once per `systems` entry. |
| `neovim.outOfStorePath` | `nullOr path` | When set, symlinks the nvim config out of the store for live editing. |
| `piAgent.settings` | `attrsOf json` | Merged over shared pi defaults; set per host. |

Flake outputs declared: `modules`, `nixosConfigurations`,
`darwinConfigurations`, `homeConfigurations`, `formatter`, `checks`,
`devShells`, `packages`.

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
- **`darwin-hosts.nix`** — same shape; `system` defaults to `aarch64-darwin`,
  and `stateVersion` defaults to the integer `7` (nix-darwin takes an int, not
  a release string).
- **`home-configurations.nix`** — `homeConfigs.<name>` →
  `homeManagerConfiguration` with `pkgs` from the default `nixpkgs` and
  `allowUnfree = true`, importing
  `flake.modules.homeManager."homeConfigurations/<name>" or { }`. For
  non-NixOS boxes this flake does not own.
- **`offline-installer.nix`** — for **every** entry in `nixosHosts`,
  generates `nixosConfigurations.offlineInstaller-<host>`: a minimal
  installation CD carrying that host's `toplevel` + `diskoScript` in
  `isoImage.storeContents`, with substituters and channels disabled,
  root autologin, and a `offline-installer` script that runs disko then
  `nixos-install --no-root-passwd --no-channel-copy`.

The aspect name convention is exact and load-bearing:
`"nixosConfigurations/<hostname>"`, `"darwinConfigurations/<hostname>"`,
`"homeConfigurations/<name>"`.

## Modules layer

### Features (`modules/features/`)

One flat file per feature; a directory when it has parts. Every file exports
`flake.modules.<class>.<aspect>`. Files that need shared values take `root:`
and read `root.config.<option>`.

| Feature | Classes | Aspect(s) | What it does |
| --- | --- | --- | --- |
| `boot.nix` | nixos | `boot`, `systemd-boot` | GRUB-on-EFI default; `systemd-boot` aspect `mkForce`s GRUB off |
| `display-manager.nix` | nixos | `display-manager` | ly |
| `doas.nix` | nixos | `doas` | doas replaces sudo, wheel `noPass`, `doas-sudo-shim`, `alias sudo=doas` |
| `documentation.nix` | nixos | `documentation` | disables NixOS manpages |
| `gaming.nix` | nixos | `gaming` | Steam + proton-ge |
| `git.nix` | nixos, homeManager | `git` | git on; user identity from `identity` |
| `home-manager.nix` | nixos, darwin | `home-manager` | wires HM for `identity.username`, `useGlobalPkgs`/`useUserPackages`; pulls `homeConfigurations/<hostname>` |
| `hyprland/` | nixos, homeManager | `hyprland` | see below |
| `incus.nix` | nixos | `incus` | incus + preseed bridge/profile/storage |
| `journald.nix` | nixos | `journald` | 90-day retention |
| `kitty.nix` | homeManager | `kitty` | kitty, colors from `palettes.adwaitaDarker` |
| `locale.nix` | nixos, homeManager | `locale` | `no`/`nodeadkeys`, `en_DK.UTF-8`, Europe/Oslo, timesyncd; sets hyprland kb |
| `neovim/` | nixos, homeManager | `neovim` | see below |
| `network.nix` | nixos | `network` | systemd-resolved + DoT/DNSSEC, NetworkManager, nftables, no DHCP |
| `nix.nix` | nixos | `nix` | GC, flakes, cache, nixpkgs registry -> input |
| `nix-index.nix` | homeManager | `nix-index` | prebuilt nix-index DB (`nix-index-database` input) + wrapped comma |
| `nixpkgs.nix` | nixos, darwin | `nixpkgs`, `unstable-nixpkgs` | `allowUnfree`; overlay exposing `pkgs.unstable` |
| `packages.nix` | nixos | `packages` | jq, fzf, fastfetch, tree |
| `pi-agent.nix` | homeManager | `pi-agent` (+ option `piAgent.settings`) | pi CLI + its `~/.pi/agent` files and skills |
| `plymouth.nix` | nixos | `plymouth` | plymouth + quiet boot params |
| `podman.nix` | nixos | `podman` | podman + docker compat, DNS on `podman0` |
| `rofi.nix` | homeManager | `rofi` | rofi theme generated from `palettes.ui` |
| `sound.nix` | nixos | `sound` | pipewire + rtkit |
| `tmux.nix` | homeManager | `tmux` | tmux config, status from `palettes.kanagawa` |
| `users.nix` | nixos, homeManager | `users` | primary user, groups, hashed password, zsh+starship, root locked |
| `xdg.nix` | homeManager | `xdg-user-dirs` | XDG dirs + `~/Dev` |
| `zsh.nix` | homeManager | `zsh` | oh-my-zsh, autosuggestions, syntax highlight |

Notes on specific features:

- **`hyprland/`** is split across `default.nix` (nixos + HM base),
  `bindings.nix`, `rules.nix`, `mako.nix`, `waybar.nix`, `hypridle.nix`,
  `hyprlock.nix`, `plugins.nix`, plus `assets/` and `scripts/`. It uses the
  pinned Hyprland input and its **Lua-based settings API** — binds and
  events are built with `lib.generators.mkLuaInline` and `_args` rather than
  the classic string config, e.g. `{ _args = [ (mkLuaInline ''mod .. " + Return"'') (mkLuaInline ''hl.dsp.exec_cmd("...")'') ]; }`.
  `plugins.nix` loads `hyprsplit`. The HM half reads `osConfig.programs.hyprland.*`
  for the compositor package, so it requires the NixOS half.
- **`neovim/`** ships a Lua config in-tree. `homeManager.neovim` symlinks
  `xdg.configFile."nvim".source` to the module dir (or to
  `neovim.outOfStorePath` for live editing). `init.lua` monkey-patches
  `vim.pack` so its lockfile writes to a writable data dir, because the store
  symlink is read-only. Neovim 0.12+ `vim.pack` is the plugin manager; no
  lazy.nvim.
- **`pi-agent.nix`** writes `~/.pi/agent/settings.json`, `APPEND_SYSTEM.md`
  and the `commit-style` / `comment-policy` skills, then merges
  `piAgent.settings` over the defaults; `desktop` uses it to pin its
  provider, model and thinking level.

### Profiles (`modules/profiles/`)

Profiles are ordinary aspects that import other aspects. A host chooses which
to take.

- `base` — nixos imports `boot doas documentation git home-manager journald
  locale network neovim nix nixpkgs packages podman unstable-nixpkgs users`
  and wires `homeManager.base`; darwin imports `home-manager nixpkgs` and
  wires `homeManager.base`; `homeManager.base` imports `git locale pi-agent
  tmux users xdg-user-dirs zsh`.
- `workstation` — nixos imports `display-manager fonts gtk hyprland plymouth
  sound`; `homeManager.workstation` imports `cursor gtk hyprland neovim qt
  rofi kitty`. Its NixOS half pulls in the HM half.

### Theme (`modules/theme/`)

`palette.nix` declares `palettes` and is the canonical example of a top-level
value option. `fonts` is nixos; `gtk` is nixos + homeManager; `cursor` and
`qt` are homeManager.

### Hosts (`modules/hosts/`)

Each host is a directory; `imports.nix` declares the host and its profile
list, sibling files contribute to the same
`flake.modules.nixos."nixosConfigurations/<name>"` aspect.

- **`thonkpad`** — imports `base workstation gaming`. Intel laptop: microcode,
  `intel-media-driver`, bluetooth, `fprintd`, `thermald`, TLP battery
  thresholds, disko, single-monitor kanshi profile.
- **`desktop`** — imports `base workstation gaming incus`. AMD desktop: RX
  6700 XT with 32-bit graphics and `kvm-amd`, zram, disko, two-monitor kanshi
  profile, WireGuard reverse-path off, `piAgent` defaults, SSH match blocks,
  host-specific app list.

The per-host home-manager customizations (`home.nix`, `monitors.nix`) target
the aspect `flake.modules.homeManager."homeConfigurations/<host>"`, because
`home-manager.nix` wires exactly that aspect into the user's HM imports for
the host whose `networking.hostName` matches.

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
- `checks.<system>.eval` — reads `system.config.system.build.toplevel.name`
  for every NixOS host and installer, forcing full module evaluation without
  building.

`nix flake check` skips `aarch64-darwin` unless `--all-systems`.

## Sharp edges

- **Formatters/checks are per-system.** A new `perSystem` definition merges;
  don't redeclare `systems`.
- **`stateVersion`** defaults to the nixpkgs release for NixOS and `7` for
  darwin; do not bump it without understanding the migration implications.
- **`networking.hostId`** is derived from the hostname hash. Renaming a host
  changes it.
- **The hyprland HM module depends on `osConfig`.** Importing only
  `modules.homeManager.hyprland` without the NixOS half will fail.
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
