# nixdots

## Module Reference

| Path | Arguments | Profile | Description |
|------|-----------|---------|-------------|
| `flake.factories.nixos.user` | `username` | minimal | User account + groups |
| `flake.factories.nixos.homeManager` | `username` | minimal | Home-manager setup |
| `flake.factories.nixos.shell` | `username` | minimal | Zsh as user shell |
| `flake.factories.nixos.network` | `{ dnsOverTls? }` | minimal | Network + DNS-over-TLS |
| `flake.factories.homeManager.git` | `{ name, email }` | - | Git user configuration |
| `flake.factories.homeManager.neovim` | `{ useOutOfStore?, outOfStorePath? }` | - | Neovim + LSP servers |
| `flake.modules.nixos.basicPackages` | - | minimal | jq, fzf, fastfetch, tree |
| `flake.modules.nixos.bootloader` | - | minimal | Bootloader (grub/systemdBoot via `flakeModules.bootloader.implementation`) |
| `flake.modules.nixos.debloat` | - | minimal | Disable unnecessary services |
| `flake.modules.nixos.displayManager` | - | graphical | Display manager (ly/gdm via `flakeModules.displayManager.implementation`) |
| `flake.modules.nixos.doas` | - | minimal | doas with noPass for wheel |
| `flake.modules.nixos.editor` | - | minimal | Neovim as default editor |
| `flake.modules.nixos.fonts` | - | graphical | System fonts |
| `flake.modules.nixos.git` | - | minimal | Git system-wide |
| `flake.modules.nixos.gnome` | - | - | GNOME desktop |
| `flake.modules.nixos.gtk` | - | graphical | GTK/dconf support |
| `flake.modules.nixos.hyprland` | - | graphical | Hyprland (imports homeManager.hyprland via sharedModules) |
| `flake.modules.nixos.incus` | - | - | Container/VM manager |
| `flake.modules.nixos.journald` | - | minimal | Journal retention |
| `flake.modules.nixos.locale` | - | minimal | Timezone, keyboard, locale |
| `flake.modules.nixos.nixConfig` | - | minimal | Nix settings, flakes, gc |
| `flake.modules.nixos.plymouth` | - | graphical | Boot splash |
| `flake.modules.nixos.podman` | - | - | Container runtime |
| `flake.modules.nixos.root` | - | minimal | Disable root account |
| `flake.modules.nixos.sound` | - | graphical | PipeWire audio |
| `flake.modules.homeManager.cursor` | - | graphical | Adwaita cursor theme |
| `flake.modules.homeManager.fuzzel` | - | - | App launcher (imported by hyprland) |
| `flake.modules.homeManager.gnome` | - | - | GNOME dconf settings |
| `flake.modules.homeManager.gtk` | - | graphical | GTK theming |
| `flake.modules.homeManager.hyprland` | - | - | Hyprland config (imported by nixos.hyprland) |
| `flake.modules.homeManager.locale` | - | minimal | Hyprland keyboard layout |
| `flake.modules.homeManager.qt` | - | graphical | Qt theming |
| `flake.modules.homeManager.shell` | - | minimal | Zsh + oh-my-zsh |
| `flake.modules.homeManager.tmux` | - | minimal | Tmux configuration |
| `flake.modules.homeManager.wezterm` | - | - | Terminal (imported by hyprland) |
| `flake.modules.homeManager.xdgUserDirs` | - | minimal | XDG directories |
