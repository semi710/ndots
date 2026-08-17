{ config, lib, ... }:
# For a new System Copy the generated cert and key and set it in that host's user.
let
  home = config.home.homeDirectory;

  deviceIds = {
    mach = "73YKZUL-LARTNVW-EOQVSVF-XVVT5XP-ODAH7TC-OCF6D6M-PC4BGPU-AMYP4AS";
    semi = "VIRL66U-KLPB2V5-7NHB7FU-5HYPREY-LZDGXGU-4F5VCXT-JYO3JHH-F2J2NQJ";
    jp-mbp = "3AAAQDF-H57Z4S4-4CKGZJX-BLSVSXF-SP7V2LZ-R2YQIFK-KFPG7MJ-I6RPQAQ";
    dsd = "DNPFMLD-3SFDPIJ-PVVA7VV-HWBOEOI-ABEM47N-7RU4HHQ-TOF7EHC-SXX7DQZ";
    obox = "ZYLR3CR-WE4CRVU-3V7PFAA-RI5C6CR-3DWPXVD-E6OJ4ZJ-UTRWVJ6-X4BWCQL";
  };

  mkDevice = name: id: {
    inherit name id;
    autoAcceptFolders = true;
  };

  allDevices = builtins.attrNames deviceIds;

  mkFolder = id: extra: {
    "${home}/.${id}" = rec {
      inherit id;
      name = id;
      devices = allDevices;
    }
    // extra;
  };
in
{
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      devices = lib.mapAttrs mkDevice deviceIds;

      folders = lib.mergeAttrsList [
        (mkFolder "notes" { ignorePerms = true; })
        (mkFolder "dump" { })
      ];
    };
  };

  # Syncthing 2.1.x opens .stignore with O_NOFOLLOW, rejecting symlinks.
  # home.file creates nix-store symlinks, so we write a regular file via activation.
  # Runs after icloudNotesLink (MBP only) so ~/.notes symlinks resolve first.
  home.activation.stignoreNotes = lib.hm.dag.entryAfter [ "writeBoundary" "icloudNotesLink" ] ''
    if [ -L "$HOME/.notes/.stignore" ]; then
      run rm -f "$HOME/.notes/.stignore"
    fi
    run sh -c 'mkdir -p "$HOME/.notes" && printf "/.obsidian\n" > "$HOME/.notes/.stignore"'
    run chmod 644 "$HOME/.notes/.stignore"
  '';
}
