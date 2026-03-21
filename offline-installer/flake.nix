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
              flakeOutPaths =
                let
                  collector = parent: map (child: [ child.outPath ] ++ (if child ? inputs && child.inputs != { } then collector child else [ ])) (lib.attrValues parent.inputs);
                in
                lib.unique (lib.flatten (collector target));

              offlineDeps = [
                target.nixosConfigurations.${targetHost}.config.system.build.toplevel
                target.nixosConfigurations.${targetHost}.config.system.build.diskoScript
                target.nixosConfigurations.${targetHost}.config.system.build.diskoScript.drvPath
                target.nixosConfigurations.${targetHost}.pkgs.stdenv.drvPath
                target.nixosConfigurations.${targetHost}.pkgs.perlPackages.ConfigIniFiles
                target.nixosConfigurations.${targetHost}.pkgs.perlPackages.FileSlurp
                (target.nixosConfigurations.${targetHost}.pkgs.closureInfo { rootPaths = [ ]; }).drvPath
              ]
              ++ flakeOutPaths;
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

              # bloat
              documentation.nixos.enable = false;

              networking.hostName = "offline-installer";

              # tightest compression
              isoImage.squashfsCompression = "xz";
              isoImage.storeContents = offlineDeps;

              environment.systemPackages = [
                (pkgs.writeShellScriptBin "offline-installer" ''
                  umount -R /mnt 2>/dev/null
                  ${pkgs.disko}/bin/disko --mode "destroy,format,mount" --root-mountpoint /mnt --yes-wipe-all-disks --flake ${target}#${targetHost}
                  mountpoint /mnt
                  mountpoint /mnt/boot
                  nixos-install --root /mnt --no-root-password --flake ${target}#${targetHost}
                '')
              ];
            }
          )
        ];
      };
    };
}
