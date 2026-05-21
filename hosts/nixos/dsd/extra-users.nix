let
  users = {
    "sunny.sehwag" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9si+8/vDKLDskxjbmcGy/B6rKaU5M5D9E+eSQtwu3T";
    "charana.c" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjfGad/qfh3IavYYhD//1o7cYdbiBwzBfVCcawIMaTe";
    "aditya.dubey" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsdusr1XztYyE/8C1xQ9ECvXjbFPQllhkUcAXf+f4sx";
    "jashan.singh" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQ6P/mQtgM4i3sGaW8lQEiIhBsOlmE8v69RCV6TBf6D";
  };

  mkUsers = usersFromKeys: {
    nix.settings.trusted-users = builtins.attrNames usersFromKeys;
    users.users = builtins.mapAttrs (username: key: {
      isNormalUser = true;
      group = "extra";
      openssh.authorizedKeys.keys = [ key ];
    }) usersFromKeys;
  };
in
mkUsers users
