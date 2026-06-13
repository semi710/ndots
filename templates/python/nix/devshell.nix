{ config, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.ruff-format.enable = true;
      };

      devShells.default = pkgs.mkShell {
        name = "python-devshell";
        inputsFrom = [ config.pre-commit.devShell ];
        packages = with pkgs; [
          python3
          uv
          basedpyright
          just
        ];
        shellHook = ''
          echo 1>&2 "🐍: $(python --version)"
          echo 1>&2 "🧬: $(nix eval --raw --impure --expr 'builtins.currentSystem')"
        '';
      };
    };
}
