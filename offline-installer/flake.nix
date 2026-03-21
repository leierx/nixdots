{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    target.url = "path:..";
  };

  outputs =
    {
      self,
      nixpkgs,
      target,
      ...
    }:
    let
      lib = nixpkgs.lib;
      targetHost = builtins.getEnv "TARGET_HOST";
    in
    {
      nixosConfigurations.offlineInstaller = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self target targetHost; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          (
            {
              lib,
              pkgs,
              target,
              targetHost,
              ...
            }:
            let
              targetSystem = target.nixosConfigurations.${targetHost};

              # Recursively include the flake source and all flake input sources.
              recurseFlakeSources = flk: if (flk._type or "") == "flake" then [ flk.outPath ] ++ lib.concatMap recurseFlakeSources (builtins.attrValues flk.inputs) else [ flk.outPath ];

              flakeSources = lib.unique (recurseFlakeSources target);

              diskoScript = if targetSystem.config.system.build ? diskoScript then [ targetSystem.config.system.build.diskoScript ] else [ ];

              offlineDeps = [
                target.outPath
                targetSystem.config.system.build.toplevel
              ]
              ++ flakeSources
              ++ diskoScript;

            in
            {
              # locale
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

              networking.hostName = "offline-installer";

              # Smaller/faster ISO
              isoImage.squashfsCompression = lib.mkForce "zstd -Xcompression-level 15";
              networking.wireless.enable = lib.mkForce false;
              documentation.enable = lib.mkForce false;
              documentation.nixos.enable = lib.mkForce false;
              documentation.man.man-db.enable = lib.mkForce false;

              # Make the target system + flake sources available offline
              isoImage.storeContents = offlineDeps;

              # Avoid registry/network surprises during flake evaluation
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              nix.settings.flake-registry = "";
              nix.registry = lib.mkForce { };

              environment.systemPackages = [
                (pkgs.writeShellScriptBin "offline-installer" ''
                  set -euo pipefail

                  echo "Installing host: ${targetHost}"

                  ${lib.optionalString (targetSystem.config.system.build ? diskoScript) ''
                    echo "Running disko script..."
                    ${targetSystem.config.system.build.diskoScript}
                  ''}

                  echo "Running nixos-install..."
                  nixos-install \
                    --root /mnt \
                    --no-root-password \
                    --no-channel-copy \
                    --flake ${target.outPath}#${targetHost} \
                    --offline \
                    --option flake-registry ""
                '')
              ];
            }
          )
        ];
      };
    };
}
