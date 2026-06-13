{ inputs, ... }:
{
  imports = [
    (inputs.git-hooks + /flake-module.nix)
  ];

  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      pre-commit.settings = {
        hooks = {
          golangci-lint.enable = true;
          treefmt = {
            enable = true;
            entry = "${lib.getExe config.treefmt.build.wrapper}";
          };
        };
      };
    };
}
