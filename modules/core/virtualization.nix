{ config, lib, pkgs, ... }:

let
  cfg = config.dots.core.virtualization;
in
{
  options.dots.core.virtualization = {
    libvirt = {
      enable = lib.mkEnableOption "Enable libvirt-based virtualization support.";
      virtManager.enable = lib.mkEnableOption "Enable virt-manager GUI if a graphical session is available.";
    };

    docker.enable = lib.mkEnableOption "Enable rootless Docker.";
  };

  config = lib.mkMerge [
    # libvirt
    (lib.mkIf cfg.libvirt.enable {
      virtualisation.libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        allowedBridges = [ "virbr0" ];
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [
              (pkgs.OVMF.override {
                secureBoot = true;
                tpmSupport = true;
              }).fd
            ];
          };
        };
      };

      networking.firewall.trustedInterfaces = [ "virbr0" ];
    })

    # virt-manager
    (lib.mkIf (cfg.libvirt.enable && cfg.libvirt.virtManager.enable) {
      environment.systemPackages = [ pkgs.virt-manager ];

      home-manager.sharedModules = [
        ({
          dconf.settings."org/virt-manager/virt-manager/connections" = {
            uris = [ "qemu:///session" ];
            autoconnect = [ "qemu:///session" ];
          };

          home.file.".config/libvirt/qemu.conf".text = ''
            nvram = [ "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
          '';
        })
      ];
    })

    # docker
    (lib.mkIf cfg.docker.enable {
      virtualisation.docker = {
        enable = false;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      # disable rootless docker enabled on boot.
      systemd.user.services.docker.wantedBy = lib.mkForce [];

      environment.systemPackages = [ pkgs.docker-compose ];
    })
  ];
}
