# ══════════════════════════════════════════════════════════════
# MINECRAFT SERVER - PLUGINS
# ══════════════════════════════════════════════════════════════

{ flake, pkgs, ... }:
{
  # Import nix-minecraft module and overlay
  imports = [
    flake.inputs.minecraft.nixosModules.minecraft-servers
  ];

  nixpkgs.overlays = [
    flake.inputs.minecraft.overlay
  ];

  services.minecraft-servers.servers.dsd.symlinks = {
    # Generated grass block icon
    "server-icon.png" =
      pkgs.runCommand "server-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert -size 64x64 xc:none \
            -fill "#5D8C22" -draw "rectangle 0,0 64,40" \
            -fill "#8B5A2B" -draw "rectangle 0,40 64,64" \
            -fill "#6DA338" -draw "rectangle 2,2 62,38" \
            -fill "#A0522D" -draw "rectangle 2,42 62,62" \
            $out
        '';

    # TPA-only plugin (replaces EssentialsX bulk)
    "plugins/SimpleTPA.jar" = pkgs.fetchurl {
      url = "https://github.com/Jelly-Pudding/simpletpa/releases/download/1.5/simpletpa-1.5.jar";
      sha256 = "086y2hdnbp9g6xf82qh677xn7i49ka7m4c083lsxdlsxkvcq9s0s";
    };

    # Cross-version support
    "plugins/ViaVersion.jar" = pkgs.fetchurl {
      url = "https://github.com/ViaVersion/ViaVersion/releases/download/5.9.1/ViaVersion-5.9.1.jar";
      sha256 = "1pxm6d61m1l2pmwjzf8w92fcnpabvx01jmazppyq77ph1bk87ahj";
    };
    "plugins/ViaBackwards.jar" = pkgs.fetchurl {
      url = "https://github.com/ViaVersion/ViaBackwards/releases/download/5.9.1/ViaBackwards-5.9.1.jar";
      sha256 = "0s4d73gbi2mbp72520qr2nq1gqsjh8l0xz8gnzw55qnpv01xlsv7";
    };

    # Death chest
    "plugins/GraveSafe.jar" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fBkeX04T/versions/JG5sdcpZ/gravesafe-plugin-1.0.0.jar";
      sha256 = "000326bl7agwikfz4wf1sxgjnzbkrv93vbndqdcs817ihv9m5z5p";
    };

    # Proximity voice chat (bukkit-2.6.18 supports Paper 1.21.2+)
    "plugins/SimpleVoiceChat.jar" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/7ROzE7Qh/voicechat-bukkit-2.6.18.jar";
      sha256 = "05li5ic3rs1g1cq4arifwb05xh0kz6glyvfd8rnkxjrng2j0qmvb";
    };
  };
}
