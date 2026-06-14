{
  lib,
  ...
}:
{
  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = 1;
  };
  imports = map (file: ./${file}) (
    lib.filter (
      file: (file != "default.nix") && (file != "combined-system-prompt.nix") && lib.hasSuffix ".nix" file
    ) (builtins.attrNames (builtins.readDir ./.))
  );
}
