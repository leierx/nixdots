{
  lib,
  pkgs,
  targetFlake,
  targetHost,
  ...
}:
let
  targetSystem = targetFlake.nixosConfigurations.${targetHost};

  flakeOutPaths =
    let
      collector = parent: map (child: [ child.outPath ] ++ (if child ? inputs && child.inputs != { } then collector child else [ ])) (lib.attrValues parent.inputs);
    in
    lib.unique (lib.flatten (collector targetFlake));

  dependencies = [
    targetFlake.outPath
    targetSystem.config.system.build.toplevel
    targetSystem.config.system.build.diskoScript
  ]
  ++ flakeOutPaths;
in
{
  console.keyMap = "no";
  i18n.defaultLocale = "en_DK.UTF-8";
  time.timeZone = "Europe/Oslo";

  isoImage.squashfsCompression = "zstd -Xcompression-level 15";
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.man-db.enable = false;

  isoImage.storeContents = dependencies;

  # Stop installing nixpkgs registry/NIX_PATH glue
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;
  # Disable the global flake registry entirely
  nix.settings.flake-registry = "";
  nix.settings.experimental-features = [ "nix-command flakes" ];

  # Avoid a few extra nix command nags
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
