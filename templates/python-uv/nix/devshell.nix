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
        name = "python-uv-devshell";
        inputsFrom = [ ];
        packages = with pkgs; [
          python
          uv
        ];
        shellHook = ''
          echo 1>&2 "🦀: $(python --version)"
          echo 1>&2 "🧬: $(nix eval --raw --impure --expr 'builtins.currentSystem')"
        '';
      };
    };
}
