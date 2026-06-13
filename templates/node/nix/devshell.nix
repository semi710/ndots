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
        programs.prettier.enable = true;
      };

      devShells.default = pkgs.mkShell {
        name = "node-devshell";
        inputsFrom = [ config.pre-commit.devShell ];
        packages = with pkgs; [
          nodejs
          typescript-language-server
          vitejs
          nodemon
          just
        ];
        shellHook = ''
          echo 1>&2 "js: $(node --version)"
          echo 1>&2 "🧬: $(nix eval --raw --impure --expr 'builtins.currentSystem')"
        '';
      };
    };
}
