{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    target.url = "path:..";
  };

  outputs =
    { nixpkgs, target, ... }:
    let
      # impure, but makes it easy to pass a custom variable
      targetHost = builtins.getEnv "TARGET_HOST";
    in
    {
      nixosConfigurations.offlineInstaller = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          (
            { pkgs, ... }:
            {
              # locale/keymap/ntp
              console.keyMap = "no";
              i18n.defaultLocale = "en_DK.UTF-8";
              time.timeZone = "Europe/Oslo";
              services.timesyncd.enable = true;
              services.timesyncd.servers = [
                "0.no.pool.ntp.org"
                "1.no.pool.ntp.org"
                "2.no.pool.ntp.org"
                "3.no.pool.ntp.org"
              ];

              # system to be offline installed.
              environment.etc."offline-target".source = target.outPath;
              isoImage.storeContents = [ target.nixosConfigurations.${targetHost}.config.system.build.toplevel ];

              # networking
              networking.hostName = "offline-installer";
              networking.dhcpcd.enable = false;

              # cut down on build time
              isoImage.squashfsCompression = "xz";

              # install script + disko
              environment.systemPackages = [
                (pkgs.writeShellScriptBin "offline-installer" ''
                  ${pkgs.disko}/bin/disko-install --mode format --write-efi-boot-entries --flake "/etc/offline-target#${targetHost}"
                '')
              ];
            }
          )
        ];
      };
    };
}
