{
  disko.devices = {
    disk = {
      nvme1 = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_KUS020203M-B000_S3VENY0KA57892";
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
                mountOptions = [ "umask=0077" "iocharset=utf8" "noatime" ];
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
}
