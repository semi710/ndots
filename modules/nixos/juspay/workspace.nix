{ pkgs, lib, ... }:
{
  # enabled for juspay workspace
  services.postgresql = {
    enable = true;
    settings.listen_addresses = lib.mkForce "*";
    authentication = pkgs.lib.mkOverride 10 ''
      # "local" is for Unix domain socket connections only
      local   all             all                                     trust
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            trust
      # IPv6 local connections:
      host    all             all             ::1/128                 trust
      # Allow Docker containers and external connections
      host    all             all             0.0.0.0/0               trust
      # Allow replication connections from localhost
      local   replication     all                                     trust
      host    replication     all             127.0.0.1/32            trust
      host    replication     all             ::1/128                 trust

    '';
  };
  networking.firewall = {
    allowedTCPPorts = [
      5432
    ];
    allowedUDPPorts = [ 5432 ];
  };

  services.redis.servers.redis = {
    enable = true;
    port = 6379;
  };
}
