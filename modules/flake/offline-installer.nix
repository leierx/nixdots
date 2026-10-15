{
  config,
  lib,
  inputs,
  ...
}:
let
  # Every nixosHosts entry also gets an `offlineInstaller-<host>` ISO system
  # carrying its toplevel + disko destroy-format-mount script:
  #   nix build .#nixosConfigurations.offlineInstaller-<host>.config.system.build.isoImage
  installerHosts = lib.attrNames config.nixosHosts;

  mkInstaller =
    targetHost:
    let
      targetSystem = config.flake.nixosConfigurations.${targetHost};
      inherit (targetSystem.config.system.build) toplevel destroyFormatMount;
    in
    lib.nixosSystem {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (
          { pkgs, ... }:
          {
            console.keyMap = targetSystem.config.console.keyMap;
            i18n.defaultLocale = targetSystem.config.i18n.defaultLocale;
            time.timeZone = targetSystem.config.time.timeZone;

            isoImage.squashfsCompression = "zstd -Xcompression-level 22";
            isoImage.storeContents = [
              toplevel
              destroyFormatMount
            ];

            nixpkgs.hostPlatform = targetSystem.config.nixpkgs.hostPlatform;
            nix.channel.enable = false;
            nix.settings.substituters = lib.mkForce [ ];
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            services.getty.autologinUser = lib.mkForce "root";
            networking.wireless.enable = lib.mkForce false;

            environment.defaultPackages = lib.mkForce [ ];
            environment.systemPackages = [
              (pkgs.writeShellScriptBin "offline-installer" ''
                set -euo pipefail
                ${lib.getExe destroyFormatMount}
                ${lib.getExe pkgs.nixos-install} \
                  --root /mnt \
                  --no-root-passwd \
                  --no-channel-copy \
                  --system ${toplevel}
              '')
            ];
          }
        )
      ];
    };
in
{
  flake.nixosConfigurations = lib.listToAttrs (
    map (host: lib.nameValuePair "offlineInstaller-${host}" (mkInstaller host)) installerHosts
  );
}
