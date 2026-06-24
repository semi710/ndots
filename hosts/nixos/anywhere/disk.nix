# GPT + BIOS boot + ESP + LVM/ext4 root.
# Works on both BIOS and EFI systems. Change /dev/sda to match
# the target disk (check with `lsblk` on the box before deploying).
{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # BIOS boot partition — grub-install needs this on non-EFI
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          # EFI system partition
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          # Root — LVM for flexibility (resize, snapshots)
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "pool";
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
