# Simple GPT + ESP + ext4 root. No LVM, no encryption — cloud VM.
{ lib, ... }:
{
  disko.devices.disk.primary = {
    device = lib.mkDefault "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        # BIOS boot — for compatibility (grub-install on non-EFI)
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
        # Root
        root = {
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
}
