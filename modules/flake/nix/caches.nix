let
  # FIXME: re-add "https://attic.xuyh0120.win/lantian" +
  # "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" when
  # attic.xuyh0120.win is reachable again (xddxdd kernel prebuilts live
  # there); while down every path lookup burns a 15s connect timeout.
  # cache.xinux.uz is the community mirror of those prebuilts
  # (github.com/xddxdd/nix-cachyos-kernel#89), verified reachable.
  substituters = [
    "https://cache.nixos.asia/juspay"
    "https://nix-community.cachix.org"
    "https://cache.nixos.org/"
    "https://cache.nixos.asia/oss"
    "https://nvix.cachix.org"
    "https://nija.cachix.org"
    "https://hyprland.cachix.org"
    "https://cache.xinux.uz"
    "https://cache.numtide.com"
  ];
  keys = [
    "juspay:5aHaNForWL03wKOGhUn/al4BZd3HqZDWZ3hrVTcf6Fg="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU="
    "nvix.cachix.org-1:qVYAfj2oiH0DF3pSs8OfPYI6B0mAZ+h5mMajN+EOL2E="
    "nija.cachix.org-1:wJRNRxBn1M1SAgzVv5ZAMe07ky6bkSSznMH0tEOFdcA="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
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
