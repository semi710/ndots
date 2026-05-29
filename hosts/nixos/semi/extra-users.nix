let
  users = {
    "sunny.sehwag" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9si+8/vDKLDskxjbmcGy/B6rKaU5M5D9E+eSQtwu3T";
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
