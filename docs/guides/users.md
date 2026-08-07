# Users

How users are defined, where their config lives, and how to add a new one.

## Where user identity lives

All user identities are defined in [`config.nix`](https://github.com/semi710/ndots/blob/master/config.nix) at the repo root:

```nix
{
  users = {
    me = {
      username = "niksingh710";
      fullname = "Nikhil Singh";
      email = "nikhil@semi.sh";
      sshPublicKeys = [ "ssh-ed25519 AAAA... nikhil@semi.sh" ];
    };
    jp = {
      username = "nikhil.singh";
      fullname = "Nikhil Singh";
      email = "nikhil.singh@juspay.in";
      sshPublicKeys = [ "ssh-ed25519 AAAA... nikhil.singh@juspay.in" ];
    };
    # per-host overrides (obox, bbox use "nikhil" as username)
  };
}
```

This is the single source of truth for usernames, full names, emails, and SSH keys. Host configs import it as `cfg = import (flake + "/config.nix")`.

## Where user system config lives

**NixOS users are created in the common host configs, not in `users/` files:**

| Host type | Where the user is created | File |
|---|---|---|
| Workstation (dsd, semi) | `common/workstation.nix` | `users.users.nikhil.singh = { isNormalUser = true; ... }` |
| Cloud server (obox, bbox) | `common/cloud.nix` | `users.users.${username} = { isNormalUser = true; ... }` |
| Standalone (mach) | Host `default.nix` directly | User created inline |

The `hosts/nixos/<host>/users/` directory is for **home-manager config only** - what the user's home environment looks like (shell, editor, packages, AI tools). It does NOT create the system user.

## Where home-manager config lives

Each host has a `users/` directory with one `.nix` file per user:

```
hosts/nixos/dsd/users/nikhil.singh.nix    # home-manager for nikhil.singh on dsd
hosts/nixos/mach/users/niksingh710.nix    # home-manager for niksingh710 on mach
hosts/nixos/obox/users/nikhil.nix         # home-manager for nikhil on obox
hosts/darwin/jp-mbp/users/nikhil.singh.nix
```

These files import home modules (`flake.homeModules.ai`, `flake.homeModules.shell`, etc.) and set per-host overrides (git identity, syncthing creds, nvix variant, etc.).

nix-wire auto-imports these files - drop a `.nix` in `users/` and it's wired automatically. No import list to maintain.

## Adding a new user

### 1. Add identity to config.nix

```nix
users = {
  me = { ... };
  jp = { ... };
  newuser = {
    username = "newuser";
    fullname = "New User";
    email = "newuser@example.com";
    sshPublicKeys = [ "ssh-ed25519 AAAA... newuser@example.com" ];
  };
};
```

### 2. Create the system user

In the host's common config (or `default.nix` for standalone hosts):

```nix
users.users.newuser = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  openssh.authorizedKeys.keys = cfg.users.newuser.sshPublicKeys;
};
```

For extra SSH-only users (no home-manager), see `hosts/nixos/dsd/extra-users.nix` for a pattern that creates users from a key map.

### 3. Add home-manager config (if needed)

Create `hosts/nixos/<host>/users/newuser.nix`:

```nix
{ flake, ... }:
{
  imports = [
    flake.homeModules.shell
    flake.homeModules.editor
  ];
}
```

nix-wire auto-imports it. The `hm` alias (`config.hm.*`) is wired in the common configs:

```nix
# In common/workstation.nix or common/cloud.nix:
(lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" me.username ])
```

If the username differs from the default, add the alias for that user too.

## Standalone home-manager (non-NixOS)

For machines not managed by this flake's NixOS configs:

```
hosts/home/nikhil.nix    # standalone home-manager for nikhil
hosts/home/admin.nix     # standalone home-manager for admin
```

These compose `homeModules.default` + `homeModules.home-only`.

## See also

- [nix-wire: Adding Hosts](https://nix-wire.semi.sh/guides/adding-hosts/) - how nix-wire auto-wires hosts and users
- [Hosts Overview](../hosts/index.md) - all hosts and their user/module breakdown
- [Architecture](../architecture.md) - how config.nix, hosts/, and modules/ fit together
