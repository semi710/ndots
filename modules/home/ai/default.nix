{
  inputs,
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = 1;
  };
  home.packages = [ pkgs.openspec ];
  imports = inputs.nix-wire.lib.autoImportExcept ./. [
    "combined-system-prompt.nix"
  ];
}
