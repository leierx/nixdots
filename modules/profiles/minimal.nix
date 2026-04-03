{ inputs, ... }:
{
  flake.modules.profiles.nixos.minimal = {
    imports = with inputs.self.modules; [
      nixos.bootloader
      nixos.defaults
      nixos.doas
      nixos.git
      nixos.journald
      nixos.locale
      nixos.network
      nixos.nixConfig
      nixos.plymouth
      nixos.shell
      nixos.tmux
      nixos.user
      nixos.xdg
      #
      overlays.vesktop
    ];
  };
}
