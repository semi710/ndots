{ ... }:
# For a new System Copy the generated cert and key and set it in that host's user.
{
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      devices = {
        mach = {
          name = "mach";
          id = "73YKZUL-LARTNVW-EOQVSVF-XVVT5XP-ODAH7TC-OCF6D6M-PC4BGPU-AMYP4AS";
          autoAcceptFolders = true;
        };
        semi = {
          name = "semi";
          id = "UCAGOTG-DZFF3EY-NVVGRRC-OE7HPXW-AEMDVKL-Q6CVMZJ-AVOHXNC-ILUNBQD";
          autoAcceptFolders = true;
        };
        jp-mbp = {
          name = "jp-mbp";
          id = "3AAAQDF-H57Z4S4-4CKGZJX-BLSVSXF-SP7V2LZ-R2YQIFK-KFPG7MJ-I6RPQAQ";
          autoAcceptFolders = true;
        };
        dsd = {
          name = "dsd";
          id = "DNPFMLD-3SFDPIJ-PVVA7VV-HWBOEOI-ABEM47N-7RU4HHQ-TOF7EHC-SXX7DQZ";
          autoAcceptFolders = true;
        };
      };

      folders = {
        # <https://nix-community.github.io/home-manager/options.xhtml#opt-services.syncthing.settings.folders._name_.path>
        # as mentioned above `~` will be resolved
        "~/.notes" = rec {
          id = "notes";
          name = id;
          devices = [
            "semi"
            "mach"
            "jp-mbp"
          ];
        };
      };
    };
  };
}
