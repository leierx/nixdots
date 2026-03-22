{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  config = {
    disko.devices = {
      disk = {
        sda = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00"; # EFI System
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "umask=0077"
                    "iocharset=utf8"
                    "noatime"
                  ];
                };
              };
              root = {
                type = "8300"; # Linux Filesystem
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
