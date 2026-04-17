{ self, config, ... }:
let
  meta = config.meta;
  username = meta.user.username;
in
{
  flake.modules.nixos.profileMinimal = {
    imports = [
      (self.factories.nixos.user username)
      (self.factories.nixos.homeManager username)
      (self.factories.nixos.shell username)
      (self.factories.nixos.network { })
      self.modules.nixos.bootloader
      self.modules.nixos.basicPackages
      self.modules.nixos.debloat
      self.modules.nixos.doas
      self.modules.nixos.editor
      self.modules.nixos.git
      self.modules.nixos.journald
      self.modules.nixos.locale
      self.modules.nixos.nixConfig
      self.modules.nixos.root
    ];

    home-manager.users.${username}.imports = [
      self.modules.homeManager.shell
      self.modules.homeManager.locale
      self.modules.homeManager.xdgUserDirs
      self.modules.homeManager.tmux
    ];
  };
}
