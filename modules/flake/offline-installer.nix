{
  config,
  lib,
  inputs,
  ...
}:
let
  # Static list of hosts to export as `offlineInstaller-<host>` x86_64-linux package.
  installerHosts = [
    "thonkpad"
    "desktop"
  ];

  flakeOutPaths =
    let
      collect = parent: map (child: [ child.outPath ] ++ lib.optionals (child ? inputs && child.inputs != { }) (collect child)) (lib.attrValues parent.inputs);
    in
    lib.unique (lib.flatten (collect inputs.self));

  mkInstaller =
    targetHost:
    let
      targetSystem = config.nixosConfigurations.${targetHost};
    in
    lib.nixosSystem {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (
          { pkgs, ... }:
          {
            nixpkgs.hostPlatform = "x86_64-linux";

            console.keyMap = "no";
            i18n.defaultLocale = "en_DK.UTF-8";
            time.timeZone = "Europe/Oslo";

            isoImage.storeContents = [
              inputs.self.outPath
              targetSystem.config.system.build.toplevel
              targetSystem.config.system.build.diskoScript
            ]
            ++ flakeOutPaths;
            isoImage.squashfsCompression = "zstd -Xcompression-level 15";

            documentation.enable = false;
            documentation.nixos.enable = false;
            documentation.man.man-db.enable = false;

            nixpkgs.flake.setNixPath = false;
            nixpkgs.flake.setFlakeRegistry = false;
            nix.settings.flake-registry = "";
            nix.settings.experimental-features = [ "nix-command flakes" ];
            nix.settings.substituters = lib.mkForce [ ];
            nix.settings.trusted-public-keys = lib.mkForce [ ];
            nix.channel.enable = false;

            services.getty.autologinUser = lib.mkForce "root";

            environment.systemPackages = [
              (pkgs.writeShellScriptBin "offline-installer" ''
                set -euo pipefail

                ${targetSystem.config.system.build.diskoScript}

                ${lib.getExe pkgs.nixos-install} \
                  --root /mnt \
                  --no-root-password \
                  --no-channel-copy \
                  --system ${targetSystem.config.system.build.toplevel}
              '')
            ];
          }
        )
      ];
    };
in
{
  packages.x86_64-linux = lib.listToAttrs (map (host: lib.nameValuePair "installer-${host}" (mkInstaller host).config.system.build.isoImage) installerHosts);
}
