# Stirling PDF

[Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) is a self-hosted PDF manipulation tool. Runs natively on NixOS (no Docker) on obox.

## Configuration

- Branded as **"semi.sh PDF"**
- Update notifications disabled for all users
- Behind Caddy reverse proxy
- Admin configured via UI (not env vars - env-based admin only works on first boot with empty DB)

## NixOS Config

```nix
services.stirling-pdf = {
  enable = true;
  environment = {
    UI_APPNAME = "semi.sh PDF";
    UI_HOMEDESCRIPTION = "Privacy-first PDF tools, hosted on semi.sh";
    UI_APPNAVBARNAME = "semi.sh PDF";
    SYSTEM_SHOWUPDATE = "false";
    SYSTEM_SHOWUPDATEONLYADMIN = "false";
  };
};
```

## Admin Login

Set up via the web UI on first boot. If you need to reset:

```bash
# Clear state and restart
sudo rm -rf /var/lib/stirling-pdf/*
sudo systemctl restart stirling-pdf
```

Then set admin password from the UI.

## Google Drive Integration

Google Drive integration is a **paid feature** (Server plan, $99/mo). `PREMIUM_ENABLED=true` only turns on license key checks - it doesn't bypass the license. Not configured.

## Free Alternative for Drive Access

Mount rclone Google Drive as a fuse filesystem on obox, point Stirling's file picker at that path. Free, uses existing rclone config.
