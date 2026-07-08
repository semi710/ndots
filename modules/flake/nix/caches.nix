let
  substituters = [
    "https://cache.nixos.asia/juspay"
    "https://nix-community.cachix.org"
    "https://cache.nixos.org/"
    "https://cache.nixos.asia/oss"
    "https://nvix.cachix.org"
    "https://nija.cachix.org"
    "https://hyprland.cachix.org"
    "https://attic.xuyh0120.win/lantian"
    "https://cache.numtide.com"
  ];
  keys = [
    "juspay:5aHaNForWL03wKOGhUn/al4BZd3HqZDWZ3hrVTcf6Fg="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU="
    "nvix.cachix.org-1:qVYAfj2oiH0DF3pSs8OfPYI6B0mAZ+h5mMajN+EOL2E="
    "nija.cachix.org-1:REPLACE_WITH_YOUR_PUBLIC_KEY"
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

in
{
  nix.settings = {
    inherit substituters;
    trusted-substituters = substituters;
    trusted-public-keys = keys;
  };
}
