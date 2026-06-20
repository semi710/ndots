# throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-generate-config ./hardware.nix`?"
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  swapDevices = [ ];
}
