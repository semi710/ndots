{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.zfs.forceImportRoot = false;

  environment = {
    systemPackages =
      with pkgs;
      [
        git
        disko
      ]
      ++ [
        inputs.nvix.packages.${pkgs.stdenv.hostPlatform.system}.bare
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
      root.openssh.authorizedKeys = {
        inherit keys;
      };
      nixos.openssh.authorizedKeys = {
        inherit keys;
      };
    };
}
