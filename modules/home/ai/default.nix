{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.openspec ];
  imports = inputs.nix-wire.lib.autoImportExcept ./. [
    "combined-system-prompt.nix"
  ];
}
