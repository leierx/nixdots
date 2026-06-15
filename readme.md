# Todo
- [ ] https://github.com/nix-community/impermanence

## Refactors

### Theme system
- [ ] Create top-level `themes.<name>` option (palette + fonts), not under `flakeModules` or `local` — themes are platform-agnostic so they deserve their own namespace alongside `modules`
- [ ] Pick an initial palette name (`themes.kanagawa-ish`? `themes.default`?) and move the duplicated hex values out of waybar/mako/rofi/wezterm/tmux
- [ ] Add `themes.<name>.fonts.{mono,sans}` so Hack/Adwaita Sans stop being repeated
- [ ] Add a selector option (`local.activeTheme = "default"`) consumed by modules that need colors
- [ ] Move waybar style, rofi rasi, wezterm lua, tmux conf to external asset files
- [ ] Use `pkgs.substituteAll` (or a small wrapper) to inject theme colors into the asset files at build time

### User as module, not profile parameter
- [ ] Create `modules/users/leier.nix` defining `modules.nixos.users.leier` (NixOS bits: groups, shell, password) and `modules.homeManager.users.leier` (HM bits: git identity, ssh matchBlocks, zsh prefs)
- [ ] Host config imports `modules.nixos.users.leier` directly — no `profileConfig.X.user` threading
- [ ] Decide what stays in `profiles/` after this — likely just hardware/desktop bundles (`minimal`, `graphical`) without any user knowledge
- [ ] Delete `factories.homeManager` and the `factories` option in `flake/parts.nix`
- [ ] Move desktop's ssh matchBlocks into `users/leier.nix` (they're user identity, not host config)

### Module plumbing
- [ ] Add `_module.args.parts = config.modules;` in `flake/parts.nix`
- [ ] Sweep every file using `outerConfig = config` and replace with `{ parts, ... }: parts.homeManager.X`
- [ ] Rename `flakeModules.*` → `local.*` (bootloader, displayManager, git, neovim, user, etc.) — single mass rename, do last
- [ ] Decide whether to rename top-level `modules.*` → `parts.*` to match flake-parts terminology, or leave it

### Hyprland split
- [ ] Break `hyprland/bindings.nix` into `bindings/{window,workspaces,movement,launchers,screenshot,submaps}.nix`
- [ ] Generalize `mkBind` to handle mouse + modifier prefixes in one helper
- [ ] Move screenshot shell scripts to `hyprland/screenshot/*.sh`, load via `builtins.readFile`
- [ ] Delete empty `extraConfig = "";` lines in `hyprland.nix` and `rules.nix`

### Small cleanups
- [ ] Decide on gaming extras (lutris, mangohud, gamescope) — commit or delete comments
- [ ] Same for `hardware.bolt.enable` on thonkpad
- [ ] Audit `backupFileExtension = "backup"` — switch to timestamped or remove
- [ ] Comment *why* `networking.enableIPv6 = false`, or re-enable
- [ ] Move `services.gnome.sushi` + `nautilus` out of `hyprland.nix` into a `modules/files.nix`
- [ ] `tmux.nix`: drop `$UID` fallback from `TMUX_TMPDIR`, rely on `XDG_RUNTIME_DIR`

## New directions

- [ ] [nix-community/impermanence](https://github.com/nix-community/impermanence) — root-on-tmpfs, persist only what's listed
- [ ] [sops-nix](https://github.com/Mic92/sops-nix) — you already install `sops`/`age` on desktop, wire them up
- [ ] Secure Boot via [lanzaboote](https://github.com/nix-community/lanzaboote) (interacts with bootloader.implementation enum — add `"lanzaboote"` variant)
- [ ] Notification daemon enum like bootloader/displayManager (`mako` | `swaync`) for consistency
- [ ] Per-host `nix.settings.trusted-users` so `opencode`/agents can build without doas
- [ ] Auto-upgrade timer (`system.autoUpgrade`) on thonkpad, or a `nh os switch` wrapper script
- [ ] Borg/restic for rsync.net (you have the ssh key configured but no backup module)
- [ ] Move shell-related bits (zsh init, starship config) out of `user.nix` into `modules/shell.nix` — `user.nix` should just be account/identity

## Ideas to think about, not yet decided

- [ ] Split `modules/` into `modules/nixos/` and `modules/home/` directories? Currently the namespace (`modules.nixos.X` vs `modules.homeManager.X`) is the only signal — file location could mirror it
- [ ] Per-host `themes.activeTheme` so desktop and thonkpad could diverge
- [ ] NixOS tests for the offline installer — `nixos-rebuild build-vm` against the installer ISO config to catch regressions
