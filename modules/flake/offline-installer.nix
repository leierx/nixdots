{
  config,
  lib,
  inputs,
  ...
}:
let
  # Hosts that get a `system.build.offlineInstallerIso` derivation. The
  # installer is a separate nixosSystem (not a variant of the host) that
  # carries the host's toplevel + diskoScript as ISO payload.
  installerHosts = [
    "thonkpad"
    "desktop"
  ];

  # Every transitive flake input store path, bundled into the ISO so the
  # system can be rebuilt offline from the embedded flake.
  flakeOutPaths =
    let
      collect =
        parent:
        map (
          child: [ child.outPath ] ++ lib.optionals (child ? inputs && child.inputs != { }) (collect child)
        ) (lib.attrValues parent.inputs);
    in
    lib.unique (lib.flatten (collect inputs.self));

  mkInstaller =
    targetHost:
    let
      targetSystem = config.nixosConfigurations.${targetHost};
    in
    (lib.nixosSystem {
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (
          { pkgs, ... }:
          {
            console.keyMap = "no";
            i18n.defaultLocale = "en_DK.UTF-8";
            time.timeZone = "Europe/Oslo";

            isoImage.storeContents = [
              inputs.self.outPath
              targetSystem.config.system.build.toplevel
              targetSystem.config.system.build.diskoScript
            ]
            ++ flakeOutPaths;
            isoImage.squashfsCompression = "zstd -Xcompression-level 22";

            documentation.enable = false;
            documentation.nixos.enable = false;
            documentation.man.man-db.enable = false;

            nixpkgs.flake.setNixPath = false;
            nixpkgs.flake.setFlakeRegistry = false;
            nixpkgs.hostPlatform = "x86_64-linux";

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
    }).config.system.build.isoImage;

  # Module attached to every listed host: registers the iso under
  # system.build.offlineInstallerIso (freeform attr, same shape as the
  # standard system.build.toplevel / isoImage attributes).
  installerOn = hostName: {
    system.build.offlineInstallerIso = mkInstaller hostName;
  };
in
{
  modules.nixos.hosts = lib.genAttrs installerHosts installerOn;
}
