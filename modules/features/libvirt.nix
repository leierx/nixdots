{
  flake.modules.nixos.libvirt =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
        };
      };

      programs.virt-manager.enable = true;

      # the lab harness creates this bridge itself
      networking.firewall.trustedInterfaces = [ "br0" ];
    };
}
