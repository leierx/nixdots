{ pkgs, lib, ... }:
{
  dots.core.virtualization.docker.enable = true;
  dots.core.privilegeEscalation.noPasswordForWheel = true;
  dots.gui.enable = true;

  # scaling - 1440p
  dots.gui.cursor.size = 32;

  # overwriting home-manager values
  home-manager.sharedModules = [
    ({
      programs.git.includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:**/**";
          contents = {
            user = {
              name = "Lars Smith Eier";
              email = "larssmitheier@gmail.com";
            };
          };
        }
      ];

      # more scaling stuff
      dconf.settings."org/gnome/desktop/interface".text-scaling-factor = 1.1;

      wayland.windowManager.hyprland.settings = {
        general.border_size = lib.mkForce 3;
        windowrulev2 = [ "monitor DP-2, class:^(vesktop)$" ];
        exec-once = [ "vesktop" ];
      };

      programs.ssh = {
        enable = true;
        matchBlocks = {
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = [ "~/.ssh/id_ed25519" ];
          };
          "*.rsync.net" = {
            identityFile = [ "~/.ssh/id_backup" ];
            identitiesOnly = true;
          };
        };
      };
    })
  ];

  # GAMING
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true; # udev rules for controllers etc

  # wireguard
  networking.firewall.checkReversePath = false;

  hardware.keyboard.zsa.enable = true;

  # various packages
  environment.systemPackages = with pkgs; [
    tmux
    wireguard-tools
    age
    sops
    pavucontrol
    fzf
    meld
    obsidian
    fastfetch
    spotify
    brave
    vesktop
    xfce.mousepad
    pika-backup
    keymapp
    tree
  ];
}
