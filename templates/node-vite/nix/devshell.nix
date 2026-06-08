{ ... }:
{
  perSystem =
    {
      config,
      pkgs,
      self',
      ...
    }:
    {
      formatter = pkgs.nixfmt;

      devShells.default = pkgs.mkShell {
        name = "node-vite-devshell";
        inputsFrom = [ ];
        packages = with pkgs; [
          nodejs
          vitejs
          live-server
          nodemon
        ];
        shellHook = ''
          echo 1>&2 "js: $(node --version)"
          echo 1>&2 "🧬: $(nix eval --raw --impure --expr 'builtins.currentSystem')"
        '';
      };
    };
}
