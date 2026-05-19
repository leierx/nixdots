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
            isoImage.squashfsCompression = "zstd -Xcompression-level 22";
            isoImage.storeContents = [
              targetSystem.config.system.build.toplevel
              targetSystem.config.system.build.diskoScript
            ];
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
                ${targetSystem.config.system.build.diskoScript}
                ${lib.getExe pkgs.nixos-install} \
                  --root /mnt \
                  --no-root-passwd \
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
