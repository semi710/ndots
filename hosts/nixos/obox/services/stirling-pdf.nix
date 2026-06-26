# Stirling PDF — NixOS native service (no Docker).
{ ... }:
{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 4080;
      UI_APPNAME = "semi.sh PDF";
      UI_HOMEDESCRIPTION = "Privacy-first PDF tools, hosted on semi.sh";
      UI_APPNAVBARNAME = "semi.sh PDF";
      SYSTEM_SHOWUPDATE = "false";
      SYSTEM_SHOWUPDATEONLYADMIN = "false";
    };
  };
}
