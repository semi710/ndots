{
  flake,
  pkgs,
  lib,
  ...
}:
{
  nix = {
    # Choose from https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=nix
    package = lib.mkForce pkgs.nixVersions.latest;

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    nixPath = [
      "nixpkgs=${flake.inputs.nixpkgs}"
      "nixpkgs-stable=${flake.inputs.nixpkgs-stable}"
    ]; # Enables use of `nix-shell -p ...` etc
    registry = {
      nixpkgs.flake = flake.inputs.nixpkgs; # Make `nix shell` etc use pinned nixpkgs
      nixpkgs-stable.flake = flake.inputs.nixpkgs-stable;
    };

    settings = {
      # list-typed option; nix-wire's mkDefault "nix-command flakes" string
      # fails eval on nixpkgs that type-checks it
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      extra-platforms = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "aarch64-darwin x86_64-darwin";
      # Nullify the registry for purity.
      flake-registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}'';
      trusted-users = [ (lib.optionalString pkgs.stdenv.hostPlatform.isLinux "@wheel") ];
    };
  };
}
