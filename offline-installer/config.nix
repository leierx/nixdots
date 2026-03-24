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
  # locale
  console.keyMap = "no";
  i18n.defaultLocale = "en_DK.UTF-8";
  time.timeZone = "Europe/Oslo";
  #
  isoImage.storeContents = dependencies;
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.man-db.enable = false;
  # Stop installing nixpkgs registry/NIX_PATH glue
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;
  # Disable the global flake registry
  nix.settings.flake-registry = "";
  nix.settings.experimental-features = [ "nix-command flakes" ];
  # Disable all binary caches (e.g. cache.nixos.org)
  nix.settings.substituters = lib.mkForce [ ];
  nix.settings.trusted-public-keys = lib.mkForce [ ];
  # Avoid a few extra nix command nags
  nix.channel.enable = false;
  # I run "sudo -i" either way
  services.getty.autologinUser = lib.mkForce "root";
  # Packages + install script
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
