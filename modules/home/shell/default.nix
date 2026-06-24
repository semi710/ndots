{ inputs, pkgs, ... }:
{
  imports = inputs.nix-wire.lib.autoImport ./.;

  programs.nix-your-shell.enable = true;
  home.packages = with pkgs; [
    devenv
    nixpkgs-track
    nixpkgs-manual
    nixpkgs-review
    nh
    duf
  ];
}
