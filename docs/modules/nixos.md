# NixOS Modules

NixOS system modules live in `modules/nixos/`. Each is exposed as `flake.nixosModules.<name>` and can be imported into any NixOS configuration.

## Available Modules

| Module | Flake output | Description |
|---|---|---|
| [base](#basenix-defaultnix) | `nixosModules.default` | Base system: nix settings, stylix, home-manager, base packages |
| [beszel](#beszelnix) | `nixosModules.beszel` | Beszel monitoring agent |
| [filebrowser](#filebrowsernix) | `nixosModules.filebrowser` | FileBrowser Quantum web file manager |
| [virtualisation](#virtualisationnix) | `nixosModules.virtualisation` | Docker (system + rootless) + Podman |
| [tailscale](#tailscalenix) | `nixosModules.tailscale` | Tailscale mesh VPN |
| [intel](#intelnix) | `nixosModules.intel` | Intel graphics + microcode |
| [stylix](#stylixnix) | `nixosModules.stylix` | Stylix theming wiring |
| [hardware](#hardware) | `nixosModules.hardware` | Audio (pipewire), bluetooth, touchpad |
| [hyprland](#hyprland) | `nixosModules.hyprland` | Hyprland window manager + home imports |
| [juspay](#juspay) | `nixosModules.juspay` | Juspay workspace config (openssh, docker, postgres) |
| [minecraft](#minecraft) | `nixosModules.minecraft` | Minecraft Paper server + plugins |

## Importing

```nix
{ flake, ... }: {
  imports = [
    flake.nixosModules.default        # base system
    flake.nixosModules.tailscale      # mesh VPN
    flake.nixosModules.virtualisation # docker + podman
    flake.nixosModules.beszel         # monitoring agent
    flake.nixosModules.filebrowser    # web file manager
  ];
}
```

---

## base.nix - `default.nix`

The base NixOS module. Imported by nearly every host.

**What it does:**

- Imports `flakeModules.nix` (nix settings, gc, caches, registry)
- Imports `nixosModules.stylix` (theming)
- Adds `homeModules.default` to `home-manager.sharedModules` (so every user gets the base home setup: shell, editor, ssh, fonts)
- Sets `home-manager.backupFileExtension = "backup"`
- Enables `nix-ld` (run unpatched binaries) and `envfs` (`/usr/bin/env` shim)
- Installs base system packages: bash, coreutils, curl, wget, git, gnutar, gzip, xz, xdg-utils, openssh
- Applies the `nix-cachyos-kernel` overlay

**Options:** none - it's a plain module, not an option-bearing one.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.default ];
}
```

---

## beszel.nix

Beszel monitoring **agent**. Reports system + Docker stats to the hub on obox.

**What it does:**

- Enables `services.beszel.agent`
- Opens the agent firewall port
- Sets `HUB_URL = "http://obox:3090"`, `LISTEN = "45876"`
- Embeds the hub's SSH public key (`KEY`) for agent authentication
- Creates a `beszel-token` group for sops token access
- Disables `PrivateUsers` (needed for Docker socket access)

**Options:** The module sets defaults but hosts override:

| Setting | Default | Host override |
|---|---|---|
| `HUB_URL` | `http://obox:3090` | - |
| `DOCKER_HOST` | `unix:///var/run/docker.sock` | workstations: `unix:///run/user/1000/docker.sock` |
| `TOKEN_FILE` | (unset) | set from sops per-host |

**Usage:**

```nix
{ flake, config, ... }: {
  imports = [ flake.nixosModules.beszel ];

  # Wire the enrollment token from sops
  sops.secrets."beszel/token" = {
    sopsFile = "${flake}/secrets/server.yaml";
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE =
    config.sops.secrets."beszel/token".path;

  # For rootless docker, run as user:
  systemd.services.beszel-agent = {
    serviceConfig.DynamicUser = lib.mkForce false;
    serviceConfig.User = lib.mkForce "myuser";
    serviceConfig.Group = lib.mkForce "beszel-token";
  };
}
```

!!! warning "Rootless Docker"
    On hosts with rootless Docker, the agent must run as the user to traverse the `0700` socket dir. See [Beszel service docs](../services/beszel.md).

---

## filebrowser.nix

FileBrowser Quantum - a web-based file manager. Runs as root for full filesystem access, Tailscale-only.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `services.filebrowser-quantum.enable` | bool | `false` | Enable the service |
| `services.filebrowser-quantum.sources` | list of str | `["/"]` | Source directories to serve |
| `services.filebrowser-quantum.home` | str | *(required)* | User home dir (auto-added as source) |
| `services.filebrowser-quantum.port` | port | `4321` | Listen port |
| `services.filebrowser-quantum.user` | str | `"root"` | systemd user |
| `services.filebrowser-quantum.passwordFile` | path | *(required)* | sops secret with admin password |

The admin username is auto-derived from `config.networking.hostName`. Update checks are disabled. The `tailscale0` interface is trusted (Tailscale-only access).

**Usage:**

```nix
{ flake, config, ... }: {
  imports = [ flake.nixosModules.filebrowser ];

  services.filebrowser-quantum = {
    enable = true;
    home = "/home/myuser";
    sources = [ "/" "/mnt/media" ];
  };
  sops.secrets."filebrowser/myhost" = { };
  services.filebrowser-quantum.passwordFile =
    config.sops.secrets."filebrowser/myhost".path;
}
```

!!! note "Admin login"
    Username = hostname, password = value in sops secret. Convention: `<host>@filebrowser`.

---

## virtualisation.nix

Enables both Docker and Podman.

**What it does:**

```nix
virtualisation.docker = {
  enable = true;
  rootless = { enable = true; setSocketVariable = true; };
};
virtualisation.podman.enable = true;
```

**Notes:**

- `podman.dockerSocket.enable` is **not** set - it conflicts with `docker.enable` (both claim `/var/run/docker.sock`)
- `oci-containers` defaults to podman if both are enabled. Force docker with `virtualisation.oci-containers.backend = "docker"`
- Rootless Docker socket is at `/run/user/<uid>/docker.sock` (inside a `0700` dir)

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.virtualisation ];
}
```

---

## tailscale.nix

A minimal module - just enables the Tailscale service. Hosts wire the auth key from sops.

**What it does:**

```nix
services.tailscale.enable = true;
```

**Usage:**

```nix
{ flake, config, ... }: {
  imports = [ flake.nixosModules.tailscale ];
  sops.secrets."tailscale_auth_key" = { };
  services.tailscale.authKeyFile =
    config.sops.secrets."tailscale_auth_key".path;
}
```

!!! tip "Tailscale-only services"
    To make a service reachable only via Tailscale, trust the interface:
    ```nix
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    ```

---

## intel.nix

Intel CPU microcode + graphics drivers.

**What it does:**

- `hardware.cpu.intel.updateMicrocode` (from redistributable firmware)
- `hardware.graphics.enable = true` with Intel media driver + compute runtime
- 32-bit graphics packages (for older games/wine)
- `LIBVA_DRIVER_NAME = "iHD"` (forces intel-media-driver)

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.intel ];
}
```

---

## stylix.nix

Wires the Stylix NixOS module + the shared home stylix config. Provides cross-platform theming (colors, fonts, wallpapers) to all NixOS and home-manager targets.

**What it does:**

```nix
imports = [
  flake.inputs.stylix.nixosModules.stylix
  (flake + /modules/home/stylix/config.nix)
];
home-manager.sharedModules = [ { stylix.enableReleaseChecks = false; } ];
```

The actual theme config (kanagawa-dragon, fonts, wallpaper, opacity) is in `modules/home/stylix/config.nix`, shared by NixOS, Darwin, and standalone home-manager.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.stylix ];
  # Theme is set in modules/home/stylix/config.nix - override there or per-host:
  # stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
}
```

---

## hardware

Auto-imported directory (`modules/nixos/hardware/`). Import via `flake.nixosModules.hardware`.

### audio.nix

PipeWire audio server (replaces PulseAudio).

- `services.pipewire.enable` + alsa + pulse + jack
- `wireplumber` enabled, libcamera monitor disabled
- `security.rtkit.enable` (real-time scheduling)
- Installs `pavucontrol`

### bluetooth.nix

- `hardware.bluetooth.enable` + powerOnBoot
- Bluez with experimental features (Source, Sink, Media, Socket)
- Disables `telephony_client` (workaround for nixpkgs#114222)

### touchpad.nix

- `services.libinput` with natural scrolling + disable while typing

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.hardware ];
  # imports audio + bluetooth + touchpad
}
```

---

## hyprland

Auto-imported directory (`modules/nixos/hyprland/`). Import via `flake.nixosModules.hyprland`.

### default.nix

Enables Hyprland with UWSM (Universal Wayland Session Manager):

- `programs.hyprland.enable` with XWayland + systemd
- `withUWSM = true`
- Mesa graphics from hyprland's nixpkgs (version-matched)
- PAM service for hyprlock (`auth include login`)
- `NIXOS_OZONE_WL = "1"` (Wayland for Electron apps)
- Adds hyprland cachix substituter
- Nullifies the home-manager hyprland package (system provides it)

### home-imports.nix

Adds home-manager modules for the full desktop experience:

```nix
home-manager.sharedModules = [
  flake.homeModules.default    # base home (shell, editor, fonts)
  flake.homeModules.packages   # GUI packages, nixcord
  flake.homeModules.terminal   # kitty
  flake.homeModules.mpv        # media player
  flake.homeModules.zathura    # PDF viewer
  flake.homeModules.browser    # Zen browser
  flake.homeModules.hyprland   # Hyprland home config (config, keymaps, rofi, idle, lock)
];
```

### overlays.nix

Injects Stylix-themed rofi clients/menus (from the `utils` flake) and patches Mailspring for Wayland.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.hyprland ];
  # This pulls in the full desktop: Hyprland + all home modules above
}
```

---

## juspay

Auto-imported directory for Juspay workspace machines. Import via `flake.nixosModules.juspay`.

### shared-config.nix

Shared Juspay environment:

- zsh as default shell, `TERM=xterm-256color`
- OpenSSH with `AcceptEnv` for `JUSPAY_API_KEY`, `ANTHROPIC_*`, `GITHUB_*`, `CLAUDE_*`
- Docker (system + rootless)
- Tailscale
- StevenBlack hosts blocking + NetworkManager
- Timezone `Asia/Kolkata`, locale `en_US.UTF-8`
- systemd-boot, passwordless sudo

### workspace.nix

Development databases:

- **PostgreSQL** with `pg_partman` extension, listening on all interfaces, trust auth (for dev)
- Firewall opens 5432 (TCP + UDP)
- **Redis** on port 6379

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.juspay ];
  # shared-config + workspace (postgres + redis)
}
```

---

## minecraft

Auto-imported directory (`modules/nixos/minecraft/`). Import via `flake.nixosModules.minecraft`. Runs a Paper Minecraft server with plugins.

### server.nix

- `services.minecraft-servers` with EULA accepted, firewall opened
- Server `dsd` using `pkgs.paperServers.paper`
- `server-port = 25565`, survival, normal difficulty, max 20 players
- `online-mode = false` (offline mode), whitelist enabled
- Command aliases routing `tpa`/`tpaccept`/`tpdeny` to SimpleTPA
- UDP port 24454 open (Simple Voice Chat)

### plugins.nix

Plugins fetched via `fetchurl` and symlinked:

| Plugin | Purpose |
|---|---|
| SimpleTPA | Teleport requests (`/tpa`) |
| ViaVersion + ViaBackwards | Cross-version support |
| DeathChest | Death chest (replaces GraveSafe which duped items) |
| ServerHomes | `/home` and `/sethome` |
| SimpleVoiceChat | Proximity voice chat |

Also generates a `server-icon.png` via ImageMagick.

### users.nix

Whitelist of three players (semi710, LightX017, fiery518) with their UUIDs.

**Usage:**

```nix
{ flake, ... }: {
  imports = [ flake.nixosModules.minecraft ];
  # Server named "dsd" starts automatically
}
```

!!! note "Server name"
    The server is named `dsd` (hardcoded in `server.nix` and `users.nix`). To run on a different host, copy and rename.
