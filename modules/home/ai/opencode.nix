{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  openagents-control = inputs.openagents-control;
  claude-code = inputs.claude-code;

  # Read registry
  registry = builtins.fromJSON (builtins.readFile "${openagents-control}/registry.json");

  # Profile to install
  profile = "developer";

  # Get components for the profile
  allComponents = registry.profiles.${profile}.components or [ ];

  # Convert component spec to file mapping
  componentToFile =
    spec:
    let
      parts = lib.splitString ":" spec;
      compType = lib.elemAt parts 0;
      compId = lib.elemAt parts 1;
      # Registry uses plural keys
      registryKey = if lib.hasSuffix "s" compType then compType else compType + "s";
      components = registry.components.${registryKey} or [ ];
      matches = c: c.id == compId || lib.elem compId (c.aliases or [ ]);
      component = lib.findFirst matches null components;
    in
    if component == null then
      null
    else
      {
        name = ".config/opencode/${lib.removePrefix ".opencode/" component.path}";
        value.source = "${openagents-control}/${component.path}";
      };

  # Combine all system prompt markdown files
  combinedSystemPrompt = import ./combined-system-prompt.nix { inherit lib; };

  # Local skills directory (directories only)
  skillsDir = ./skills;
  skillsEntries = builtins.readDir skillsDir;
  allSkills = lib.filter (name: skillsEntries.${name} == "directory") (lib.attrNames skillsEntries);

  # File mappings from registry components
  componentFiles = lib.listToAttrs (lib.filter (x: x != null) (map componentToFile allComponents));

  # External skills sourced directly from anthropics/claude-code
  externalSkills = {
    ".config/opencode/skills/frontend-design/SKILL.md".source =
      "${claude-code}/plugins/frontend-design/skills/frontend-design/SKILL.md";
  };

  # Local skills mapped to ~/.config/opencode/skills/
  localSkills = lib.optionalAttrs (builtins.pathExists skillsDir) (
    lib.mapAttrs' (name: _: {
      name = ".config/opencode/skills/${name}/SKILL.md";
      value.source = "${skillsDir}/${name}/SKILL.md";
    }) (lib.filterAttrs (_: type: type == "directory") skillsEntries)
  );

in
{
  home.sessionVariables.OPENCODE_ENABLE_EXA = 1;
  programs.opencode = {
    enable = true;
    package = pkgs.opencode-vim;
    # pkgs.llm-agents.opencode;
    enableMcpIntegration = true;
    web = {
      enable = lib.mkDefault false;
      extraArgs = [ "--mdns" ];
    };
    settings = {
      provider = {
        anthropic.models = {
          claude-opus-4-7 = {
            id = "claude-opus-4-7";
            name = "gawwd";
          };
          claude-sonnet-4-6 = {
            id = "claude-sonnet-4-6";
            name = "worker";
          };
          claude-haiku-4-5 = {
            id = "claude-haiku-4-5";
            name = "haiya";
          };
        };
      };
      default_agent = "OpenAgent";
      autoupdate = true;
      agent = {
        OpenAgent = {
          system_prompt = combinedSystemPrompt;
          skills = allSkills;
        };
      };
    };

    tui = {
      vim_system_clipboard_register = true;
      vim_escape_sequence = "jk";
      vim_enter_submit = true;
      vim_insert_after_submit = true;
    };
  };

  home.file = componentFiles // externalSkills // localSkills;
}
