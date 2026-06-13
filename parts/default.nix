{ inputs, self, ... }:
{
  imports = [
    (inputs.git-hooks + /flake-module.nix)
    inputs.treefmt-nix.flakeModule
  ];

  flake = {
    disko = import ./disko;
    iso = import ./iso { inherit inputs self; };
  };

  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };

      devShells.default = pkgs.mkShell {
        name = "ndots";
        meta.description = "Dev environment for nixos-config";
        inputsFrom = [ config.pre-commit.devShell ];
        packages = with pkgs; [
          just
        ];
        shellHook = ''
          echo 1>&2 "🐼: $(id -un) | 🧬: $(nix eval --raw --impure --expr 'builtins.currentSystem') | 🐧: $(uname -r) "
          echo 1>&2 "Ready to work on ndots!"
        '';
      };

      pre-commit.settings = {
        hooks.treefmt = {
          enable = true;
          entry = "${lib.getExe config.treefmt.build.wrapper}";
        };
      };
    };
}
