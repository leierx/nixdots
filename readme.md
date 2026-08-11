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

## New directions
- [ ] [nix-community/impermanence](https://github.com/nix-community/impermanence) — root-on-tmpfs, persist only what's listed
- [ ] Notification daemon enum like bootloader/displayManager (`mako` | `swaync`) for consistency
- [ ] Per-host `nix.settings.trusted-users` so `opencode`/agents can build without doas
- [ ] Borg/restic for rsync.net (you have the ssh key configured but no backup module)
- [ ] Move shell-related bits (zsh init, starship config) out of `user.nix` into `modules/shell.nix` — `user.nix` should just be account/identity

## Ideas to think about, not yet decided
- [ ] Per-host `themes.activeTheme` so desktop and thonkpad could diverge
- [ ] NixOS tests for the offline installer — `nixos-rebuild build-vm` against the installer ISO config to catch regressions
