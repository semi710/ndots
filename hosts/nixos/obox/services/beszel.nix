# Beszel hub + agent wiring for obox.
# The hub runs here; the shared agent module (modules/nixos/beszel.nix) also
# enables a self-monitoring agent on this host.
{
  config,
  lib,
  ...
}:
{
  # One-time setup after a fresh hub DB: enable the universal token so agents
  # can self-register. Login to get a JWT, then GET with query params:
  #   JWT=$(curl -s http://localhost:3090/api/collections/users/auth-with-password \
  #     -H "Content-Type: application/json" \
  #     -d '{"identity":"<email>","password":"<pass>"}' | jq -r .token)
  #   curl "http://localhost:3090/api/beszel/universal-token?enable=1&permanent=1&token=<token>" \
  #     -H "Authorization: $JWT"
  # Token value is in secrets/server.yaml under beszel.token.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 3090;
    # Used for links in notifications. Without it PocketBase defaults to
    # http://localhost:8090, which is what showed up in the notification test.
    environment.APP_URL = "https://beszel.semi.sh";
  };

  users.groups.beszel-hub-key = { };

  sops.secrets."beszel/ssh_key" = {
    group = "beszel-hub-key";
    mode = "0440";
  };
  sops.secrets."beszel/username" = {
    group = "beszel-hub-key";
    mode = "0440";
  };
  sops.secrets."beszel/password" = {
    group = "beszel-hub-key";
    mode = "0440";
  };

  # sops.templates composes the env file at activation time.
  # Placeholders are replaced with actual secret values (not paths).
  sops.templates."beszel-hub-env" = {
    content = ''
      USER_EMAIL=${config.sops.placeholder."beszel/username"}
      USER_PASSWORD=${config.sops.placeholder."beszel/password"}
    '';
    group = "beszel-hub-key";
    mode = "0440";
  };

  services.beszel.hub.environmentFile = config.sops.templates."beszel-hub-env".path;

  systemd.services.beszel-hub = {
    serviceConfig.SupplementaryGroups = [ "beszel-hub-key" ];
    preStart = lib.mkBefore ''
      cp "${config.sops.secrets."beszel/ssh_key".path}" /var/lib/beszel-hub/beszel_data/id_ed25519
      chmod 0600 /var/lib/beszel-hub/beszel_data/id_ed25519
    '';
  };

  # Agent (self-monitoring) — token from sops.
  sops.secrets."beszel/token" = {
    group = "beszel-token";
    mode = "0440";
  };
  services.beszel.agent.environment.TOKEN_FILE = config.sops.secrets."beszel/token".path;
}
