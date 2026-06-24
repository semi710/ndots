# Registry profile wiring — maps openagents-control profile components
# to ~/.config/opencode/ files.
{
  inputs,
  lib,
  ...
}:
let
  openagents-control = inputs.openagents-control;
  registry = builtins.fromJSON (builtins.readFile "${openagents-control}/registry.json");
  profile = "developer";
  allComponents = registry.profiles.${profile}.components or [ ];

  componentToFile =
    spec:
    let
      parts = lib.splitString ":" spec;
      compType = lib.elemAt parts 0;
      compId = lib.elemAt parts 1;
      registryKey = if lib.hasSuffix "s" compType then compType else compType + "s";
      components = registry.components.${registryKey} or [ ];
      component = lib.findFirst (c: c.id == compId || lib.elem compId (c.aliases or [ ])) null components;
    in
    if component == null then
      null
    else
      {
        name = ".config/opencode/${lib.removePrefix ".opencode/" component.path}";
        value.source = "${openagents-control}/${component.path}";
      };
in
lib.listToAttrs (lib.filter (x: x != null) (map componentToFile allComponents))
