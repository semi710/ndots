# Docker + Podman — system (root) and rootless (user) on all hosts.
# Import this module to enable both runtimes. Beszel agent picks up
# containers via the podman docker-compatible socket.
# Note: dockerSocket.enable conflicts with docker.enable, so we don't
# enable it when system docker is also running.
{ ... }:
{
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    podman = {
      enable = true;
    };
  };
}
