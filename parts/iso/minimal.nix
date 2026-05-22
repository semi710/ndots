# Minimal Iso stands for CLI variant only
{
  inputs,
  pkgs,
  modulesPath,
  hostPlatform,
  self,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    (self.flakeModules.nix)
  ];

  boot.zfs.forceImportRoot = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs = {
    inherit hostPlatform;
  };

  environment = {
    systemPackages =
      with pkgs;
      [
        git
        disko
      ]
      ++ ([
        inputs.nvix.packages.${pkgs.stdenv.hostPlatform.system}.bare # My neovim config based on Nixvim
      ]);
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
      root.openssh.authorizedKeys = {
        inherit keys;
      };
      nixos.openssh.authorizedKeys = {
        inherit keys;
      };
    };
}
