{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # Minimal ISO: do NOT import nixosModules.default (it pulls in stylix,
  # nix-cachyos-kernel overlay, and homeModules.default with tons of fonts).
  # Instead, import only the nix config (substituters, registry, etc.).
  imports = [
    inputs.self.flakeModules.nix
  ];

  boot = {
    zfs.forceImportRoot = false;
    loader.grub.memtest86.enable = lib.mkDefault false;
  };

  # Disable redistributable firmware (saves ~100-300MB of firmware blobs)
  hardware.enableRedistributableFirmware = lib.mkDefault false;

  # We don't need sound on an install ISO
  hardware.pulseaudio.enable = false;

  # Strip documentation to save space
  documentation.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
  documentation.nixos.enable = false;

  # Only keep essential locale
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  environment = {
    systemPackages = with pkgs; [
      git
      disko
    ];
    shellAliases = {
      vim = "nvim";
    };
  };

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  users.users =
    let
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwouW1kRGVOgb58dJPwF+HCsXXYl2OUOqpxuqAXGKIZ nik.singh710@gmail.com"
      ];
    in
    {
      root.openssh.authorizedKeys.keys = keys;
      nixos = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        openssh.authorizedKeys.keys = keys;
        # Set password explicitly, suppress conflicting defaults
        password = lib.mkOverride 10 "nixos";
      };
    };

  # Minimal home-manager config — cherry-pick only needed modules and
  # force nvix bare to avoid the heavy "core" default.
  home-manager.users.nixos =
    { ... }:
    {
      # Required by home-manager
      home.stateVersion = "26.05";

      imports = [
        inputs.self.homeModules.shell
        inputs.self.homeModules.editor
        inputs.self.homeModules.ssh
        # nix-index removed: not needed on ephemeral install ISO
      ];

      # Disable android module on ISO — removes scrcpy which fails to build on aarch64
      disabledModules = [
        "${inputs.self}/modules/home/shell/android.nix"
      ];

      # Override the default "core" variant to "bare" for ISO
      nvix.variant = lib.mkForce "bare";

      # Remove fastfetch alias (not installed in minimal ISO)
      home.shellAliases.fetch = lib.mkForce "";
    };
}
