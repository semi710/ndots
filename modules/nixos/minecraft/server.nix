{ pkgs, ... }:
{
  # Simple Voice Chat UDP port
  networking.firewall.allowedUDPPorts = [ 24454 ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.dsd = {
      enable = true;
      package = pkgs.paperServers.paper-26_2;

      serverProperties = {
        server-port = 25565;
        difficulty = "normal";
        gamemode = "survival";
        max-players = 20;
        motd = "\\u00A7cDSD\\u00A7r - \\u00A7bSurvival Server\\u00A7r";
        spawn-protection = 0;
        view-distance = 12;
        simulation-distance = 10;
        enable-command-block = false;
        announce-player-achievements = true;
        allow-flight = false;
        prevent-proxy-connections = false;
        online-mode = false;
        white-list = true;
        force-gamemode = false;
      };

      files = {
        # Route teleport commands to SimpleTPA
        "commands.yml".value = {
          aliases = {
            tpa = [ "simpletpa:tpa $1-" ];
            tpaccept = [ "simpletpa:tpaccept $1-" ];
            tpdeny = [ "simpletpa:tpdeny $1-" ];
          };
        };
      };
    };
  };
}
