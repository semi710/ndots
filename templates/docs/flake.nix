{
  description = "Docs template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAll = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      apps = forAll (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          docs = {
            type = "app";
            program = "${
              pkgs.python3.withPackages (
                ps: with ps; [
                  mkdocs
                  mkdocs-material
                ]
              )
            }/bin/mkdocs";
          };
        }
      );
    };
}
