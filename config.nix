{
  users = rec {
    me = rec {
      username = "niksingh710";
      fullname = "Nikhil Singh";
      email = "nikhil@semi.sh";
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwouW1kRGVOgb58dJPwF+HCsXXYl2OUOqpxuqAXGKIZ ${email}"
      ];
    };
    obox = {
      username = "nikhil";
      inherit (me) fullname email sshPublicKeys;
    };
    bbox = {
      username = "nikhil";
      inherit (me) fullname email sshPublicKeys;
    };
    jp = rec {
      username = "nikhil.singh";
      fullname = me.fullname;
      email = "nikhil.singh@juspay.in";
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS/aon2HBvAk751UqsxVgSGq77Ug6nCHAfEYVeHkTG7 ${email}"
      ];
    };
    virt = {
      username = "virt";
      fullname = "Virtual Machine User";
      email = "virt@localhost";
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwouW1kRGVOgb58dJPwF+HCsXXYl2OUOqpxuqAXGKIZ"
      ];
      hashedPassword = "$6$jvXw5025x7XND9MV$G9meEJQJ9S0MNG3VP7EzAo02xys1L6.YRPPE2Fbksj58C9n1ZU8k5FrNdvkoZsPW3xDGjg1m9sLxpdr1.J39s/";
    };
  };

  builders = rec {
    # Shared SSH key for nix remote builds (one key pair, all machines use it)
    key = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSq2XkQgBVoDLjvh7X1ULsDIfCrRcn4HM3un2uzUUIM nix-builder@ndots";
    };

    # Common defaults for Linux builders (inherit & override per-host)
    linux = {
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      sshUser = "nikhil.singh";
    };

    dsd = linux // {
      hostName = "dsd";
      hostNames = [
        "dsd"
        "dsd.persian-vega.ts.net"
      ];
      # SSH host key — used by nix-daemon (root) for knownHosts verification
      # Update with: ssh-keyscan dsd 2>/dev/null | grep ed25519
      hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9PMm+g87zvYb85/LhAiguCWbSXlDeR56m+OV86lYbK";
    };
    semi = linux // {
      hostName = "semi";
      hostNames = [
        "semi"
        "semi.persian-vega.ts.net"
      ];
      # SSH host key — used by nix-daemon (root) for knownHosts verification
      # Update with: ssh-keyscan semi 2>/dev/null | grep ed25519
      hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9zAGumywN507wgOwNoGKjJkr5dn/TFejM7FAiKdHvg";
    };
  };
}
