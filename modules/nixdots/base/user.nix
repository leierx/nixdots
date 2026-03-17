{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.base.user;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  options.nixdots.base.user = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable nixdots.base.user";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable root user login
    users.users.root.hashedPassword = "!";

    # default shell: bash, main user: zsh
    users.defaultUserShell = pkgs.bashInteractive;
    programs.zsh.enable = true;

    # prompt
    programs.starship.enable = true;

    # Ensure primary group <username> exists
    users.groups.leier = { };

    # Create the user account
    users.users.leier = {
      isNormalUser = true;
      home = "/home/leier";
      createHome = true;
      homeMode = "0770";
      shell = pkgs.zsh;
      group = "leier";
      extraGroups = [
        "wheel" # sudo
        "networkmanager" # network control
        "video" # GPU / DRM
        "audio" # legacy but harmless
        "lp" # printing
        "scanner" # access scanners
        "libvirtd" # manage libvirt
        "kvm" # hardware virtualization
        "podman" # rootless podman
        "wireshark" # capture packets without sudo
        "input" # read raw input devices
      ];
      description = "leier";
      initialHashedPassword = "$6$IwGp276/71CzyoDG$RHOfZSCTLXN2NGk7T8QcYTx815KNhEx42ECUrNxYcdjAga0JD4EVzSgUus.WR2U44Epk8fpcnMdXTIJmYB4dd0";
    };

    # setup home-manager
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.leier = {
        home.stateVersion = config.system.stateVersion;
        programs.zsh = {
          enable = true;
          oh-my-zsh.enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          history = {
            size = 10000;
            save = 690000;
          };
          autosuggestion = {
            enable = true;
            highlight = "fg=246";
          };
          initContent = ''
            # Accept autosuggestion with Ctrl+Space
            bindkey '^ ' autosuggest-execute
          '';
        };
      };
    };
  };
}
