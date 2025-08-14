{
  description = "Minimal NixOS installation media";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      minimal_iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, lib, ... }: {
            # console
            console = { earlySetup = true; keyMap = "no"; };

            #timezone
            time.timeZone = "Europe/Oslo";

            # locale
            i18n.defaultLocale = "en_US.UTF-8";
            i18n.extraLocaleSettings = { LC_ADDRESS = "nb_NO.UTF-8"; LC_COLLATE = "nb_NO.UTF-8"; LC_CTYPE = "en_US.UTF-8"; LC_IDENTIFICATION = "nb_NO.UTF-8"; LC_MEASUREMENT = "nb_NO.UTF-8"; LC_MESSAGES = "en_US.UTF-8"; LC_MONETARY = "nb_NO.UTF-8"; LC_NAME = "nb_NO.UTF-8"; LC_NUMERIC = "nb_NO.UTF-8"; LC_PAPER = "nb_NO.UTF-8"; LC_TELEPHONE = "nb_NO.UTF-8"; LC_TIME = "nb_NO.UTF-8"; };

            # networking
            networking.hostName = "iso";
            networking.networkmanager.enable = true;
            networking.wireless.enable = false;

            # packages
            environment.systemPackages = with pkgs; [
              jq
              git
              gum
              fastfetch
              bash
              coreutils
              (writeShellScriptBin "leier-nix-install" (builtins.readFile ./install.sh))
            ];

            # ssh for remote install
            services.openssh.enable = true;
            services.openssh.settings.PermitRootLogin = "yes";
            services.openssh.settings.PasswordAuthentication = false;
            services.openssh.settings.KbdInteractiveAuthentication = false;
            users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKkHlDWS9S4YWSPSah1Pea5Jpt6+zasaPed0cR2FFhh" ];

            # nix settings.
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            # temporarily make it faster
            isoImage.squashfsCompression = "gzip -Xcompression-level 1";

            # making the shell a little more useable
            programs.neovim = { enable = true; viAlias = true; vimAlias = true; defaultEditor = true; withPython3 = false; withNodeJs = false; withRuby = false; };
            programs.starship.enable = true;
          })
        ];
      };
    };
  };
}
