# naste CLI client — endpoint only, no private creds.
# Hosts with sops add private.userFile/passFile in their user config.
{
  flake,
  ...
}:
{
  imports = [ flake.inputs.naste.homeModules.default ];

  programs.naste-client = {
    enable = true;
    endpoint = "https://paste.semi.sh";
  };
}
