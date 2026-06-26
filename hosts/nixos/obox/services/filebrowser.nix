# FileBrowser Quantum — serves / + user home (Tailscale-only).
{
  config,
  ...
}:
{
  services.filebrowser-quantum = {
    enable = true;
    home = config.hm.home.homeDirectory;
  };
  sops.secrets."filebrowser/obox" = { };
  services.filebrowser-quantum.passwordFile = config.sops.secrets."filebrowser/obox".path;
}
