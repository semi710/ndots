{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.openspec
    pkgs.nil
  ];
  imports = inputs.nix-wire.lib.autoImportExcept ./. [
    "combined-system-prompt.nix"
  ];
}
