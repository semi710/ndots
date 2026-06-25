# Docker & Podman

Container runtimes managed via a shared virtualisation module.

## Module

`modules/nixos/virtualisation.nix` enables:

- **Docker** (system + rootless)
- **Podman** (without `dockerSocket` — conflicts with Docker's socket)

```nix
virtualisation.docker = {
  enable = true;
  rootless.enable = true;
};
virtualisation.podman.enable = true;
```

## oci-containers Backend

NixOS `oci-containers` defaults to podman if both are enabled. To force docker:

```nix
virtualisation.oci-containers.backend = "docker";
```

## Rootless Docker

Rootless Docker runs per-user. The socket is at `/run/user/<uid>/docker.sock` inside a `0700` directory. Services that need to access it must run as that user.

### Beszel Agent + Rootless Docker

On workstations (semi, dsd, mach), the Beszel agent runs as the user (not DynamicUser) to traverse the `0700` path:

```nix
services.beszel.agent.environment.DOCKER_HOST = "unix:///run/user/1000/docker.sock";
systemd.services.beszel-agent = {
  serviceConfig.DynamicUser = lib.mkForce false;
  serviceConfig.User = lib.mkForce "<username>";
};
```

### System Docker (obox)

On obox, the agent keeps `DynamicUser=true` but sets `PrivateUsers=false` for Docker socket access.

## Podman Limitation

`podman.dockerSocket.enable` conflicts with `docker.enable` — both try to own `/var/run/docker.sock`. The module enables podman without the docker socket compat. Beszel can't monitor podman containers on obox.
