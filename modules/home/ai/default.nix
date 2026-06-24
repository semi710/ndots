{
  inputs,
  ...
}:
{
  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = 1;
  };
  imports = inputs.nix-wire.lib.autoImportExcept ./. [
    "combined-system-prompt.nix"
  ];
}
