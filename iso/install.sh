set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    # Attempt to rerun the script with sudo
    exec sudo bash "$0" "$@"
fi

# test internet connectivity
timeout 3 bash -c "</dev/tcp/archlinux.org/443" &> /dev/null

# print nixos logo 4 fun
clear ; fastfetch -s ":"

# pretty print disks, then pick one
clear ; gum style --border double --margin "0 1" --padding "1 2" --border-foreground "006" """Please Select disk

$(lsblk -o NAME,SIZE,MOUNTPOINT,TYPE)"""
installdisk="$(gum choose --cursor.foreground=002 $(lsblk -dnpo NAME -I 8,259,253,254,179 | grep -Pv "mmcblk\dboot\d"))"

# sanity check
[[ -n "${installdisk}" && -b "${installdisk}" ]]

clear ; gum confirm """Proceed with these settings?
Disk: ${installdisk}""" --selected.background "001" --prompt.foreground="006"

clear ; echo "Partitioning disk..."

# Use a subshell to temporarily disable exit on error
(
    set +e
    umount -AR /mnt &>/dev/null
    swapoff -a &>/dev/null
    wipefs -af "${installdisk}" &>/dev/null
)

sfdisk "${installdisk}" &>/dev/null <<EOF
label: gpt
;512Mib;U;*
;+;L
EOF

json_disk_info="$(lsblk -pJ ${installdisk})"
boot_disk="$(jq -r --arg disk "${installdisk}" '.blockdevices[] | select (.name == $disk).children[0].name' <<< "${json_disk_info}")"
root_disk="$(jq -r --arg disk "${installdisk}" '.blockdevices[] | select (.name == $disk).children[1].name' <<< "${json_disk_info}")"

# sanity check
for disk in "${boot_disk}" "${root_disk}"
do
    [[ -n "${disk}" && -b "${disk}" ]]
done

mkfs.fat -I -F 32 "${boot_disk}" -n NIXBOOT &>/dev/null
mkfs.ext4 -F "${root_disk}" -L NIXROOT &>/dev/null

start_time=$SECONDS
while [[ ! -e "/dev/disk/by-label/NIXROOT" || ! -e "/dev/disk/by-label/NIXBOOT" ]] && [[ $((SECONDS - start_time)) -lt 30 ]]; do
    sleep 2
done

mount /dev/disk/by-label/NIXROOT /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/NIXBOOT /mnt/boot

mkdir /root/basic_ass_system
cat <<EOF > /root/basic_ass_system/flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }@flakeInputs: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit flakeInputs; };
        modules = [
          ({ pkgs, ... }: {
            system.stateVersion = "24.11";

            # hardware + boot
            fileSystems = {
              "/boot" = { device = "/dev/disk/by-label/NIXBOOT"; fsType = "vfat"; };
              "/" = { device = "/dev/disk/by-label/NIXROOT"; fsType = "ext4"; };
            }; swapDevices = [];

            boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ]; #basic shit needed to boot.
            hardware.enableRedistributableFirmware = true;

            boot.loader.systemd-boot.enable = true;

            # console
            console = { earlySetup = true; keyMap = "no"; };

            #timezone
            time.timeZone = "Europe/Oslo";

            # locale
            i18n.defaultLocale = "en_US.UTF-8";
            i18n.extraLocaleSettings = { LC_ADDRESS = "nb_NO.UTF-8"; LC_COLLATE = "nb_NO.UTF-8"; LC_CTYPE = "en_US.UTF-8"; LC_IDENTIFICATION = "nb_NO.UTF-8"; LC_MEASUREMENT = "nb_NO.UTF-8"; LC_MESSAGES = "en_US.UTF-8"; LC_MONETARY = "nb_NO.UTF-8"; LC_NAME = "nb_NO.UTF-8"; LC_NUMERIC = "nb_NO.UTF-8"; LC_PAPER = "nb_NO.UTF-8"; LC_TELEPHONE = "nb_NO.UTF-8"; LC_TIME = "nb_NO.UTF-8"; };

            # networking
            networking.hostName = "nixos";
            networking.networkmanager.enable = true;
            networking.wireless.enable = false;

            # packages
            environment.systemPackages = with pkgs; [ git fastfetch coreutils ];

            # nix settings.
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            # autologin as root
	          services.getty.autologinUser = "root";

            # making the shell a little more useable
            programs.neovim = { enable = true; viAlias = true; vimAlias = true; defaultEditor = true; withPython3 = false; withNodeJs = false; withRuby = false; };
            programs.starship.enable = true;
          })
        ];
      };
    };
  };
}
EOF

nixos-install --cores 0 --no-root-passwd --no-write-lock-file --option eval-cache false --root /mnt --flake "/root/basic_ass_system#default"
