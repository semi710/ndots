{ inputs, self, ... }:
{
  imports = [
    (inputs.git-hooks + /flake-module.nix)
    inputs.treefmt-nix.flakeModule
  ];

  flake = {
    disko = import ./disko;
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

      apps.docs =
        let
          env = pkgs.python3.withPackages (
            ps: with ps; [
              mkdocs
              mkdocs-material
            ]
          );
        in
        {
          type = "app";
          program = lib.getExe env;
        };

      pre-commit.settings = {
        hooks.treefmt = {
          enable = true;
          entry = "${lib.getExe config.treefmt.build.wrapper}";
        };
        # advice-only drift hint; verbose so the hint shows on success too
        hooks.app-drift = {
          enable = true;
          always_run = true;
          pass_filenames = false;
          verbose = true;
          entry = "just app-sync-dry";
        };
      };
    };
}
