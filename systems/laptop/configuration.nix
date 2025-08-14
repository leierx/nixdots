{ pkgs, lib, ... }:
{
  dots.core.virtualization.docker.enable = true;
  dots.core.privilegeEscalation.noPasswordForWheel = true;
  dots.gui.enable = true;

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

      wayland.windowManager.hyprland.settings = {
        monitor = "eDP-1,1920x1080@60,0x0,1";
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

  # wireguard
  networking.firewall.checkReversePath = false;

  # ZSA keyboard support
  hardware.keyboard.zsa.enable = true;

  # various packages
  environment.systemPackages = with pkgs; [
    wireguard-tools
    age
    sops
    pavucontrol
    fzf
    meld
    obsidian
    fastfetch
    spotify
    vesktop
    xfce.mousepad
    keymapp
    tree
  ];
}
