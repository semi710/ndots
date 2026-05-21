let
  users = { };

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
