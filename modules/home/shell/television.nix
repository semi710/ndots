{ ... }:
{
  programs = {
    television.enable = true;

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
      settings.indexes = [
        "nixpkgs"
        "home-manager"
        "nixos"
        "darwin"
        "nur"
        "noogle"
      ];
    };
  };

  home.shellAliases.ns = "tv nix-search-tv";
}
