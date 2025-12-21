{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixdots.services.libvirt;
in
{
  options.nixdots.services.libvirt = {
    enable = lib.mkEnableOption "Enable libvirt / KVM virtualisation";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      allowedBridges = [ "virbr0" ];

      qemu = {
        runAsRoot = true;
        swtpm.enable = true;
      };
    };

    networking.firewall.trustedInterfaces = [ "virbr0" ];
  };
}
