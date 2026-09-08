# Skills wiring — maps skill sources to ~/.config/opencode/skills/.
# Sources: local (./skills/), ponytail (vendored), workmux (flake), external (claude-code).
{
  inputs,
  lib,
  ...
}:
let
  ponytail = inputs.ponytail;
  claude-code = inputs.claude-code;
  workmux = inputs.workmux;

  skillsDir = ../skills;
  skillsEntries = builtins.readDir skillsDir;
  ponytailSkillsDir = ponytail + "/skills";
  ponytailSkillsEntries = builtins.readDir ponytailSkillsDir;
  workmuxSkillsDir = workmux.outPath + "/skills";
  workmuxSkillsEntries = builtins.readDir workmuxSkillsDir;

  isPonytailSkillDir =
    name:
    ponytailSkillsEntries.${name} == "directory"
    && builtins.pathExists (ponytailSkillsDir + "/${name}/SKILL.md");

  isWorkmuxSkillDir =
    name:
    workmuxSkillsEntries.${name} == "directory"
    && builtins.pathExists (workmuxSkillsDir + "/${name}/SKILL.md");

  localSkillNames = lib.filter (name: skillsEntries.${name} == "directory") (
    lib.attrNames skillsEntries
  );

  ponytailSkillNames = lib.filter isPonytailSkillDir (lib.attrNames ponytailSkillsEntries);
  workmuxSkillNames = lib.filter isWorkmuxSkillDir (lib.attrNames workmuxSkillsEntries);
  # File mappings for a target skills directory prefix
  mkSkillFiles =
    prefix:
    let
      local = lib.mapAttrs' (name: _: {
        name = "${prefix}/${name}/SKILL.md";
        value.source = "${skillsDir}/${name}/SKILL.md";
      }) (lib.filterAttrs (_: type: type == "directory") skillsEntries);

      workmux = lib.listToAttrs (
        map (name: {
          name = "${prefix}/${name}/SKILL.md";
          value.source = "${workmuxSkillsDir}/${name}/SKILL.md";
        }) workmuxSkillNames
      );

      external = {
        "${prefix}/frontend-design/SKILL.md".source =
          "${claude-code}/plugins/frontend-design/skills/frontend-design/SKILL.md";
      };
    in
    local // workmux // external;
in
{
  # Skill name list for the agent config
  skills = localSkillNames ++ ponytailSkillNames ++ workmuxSkillNames;

  # File mappings for ~/.config/opencode/skills/
  files =
    mkSkillFiles ".config/opencode/skills"
    // lib.listToAttrs (
      map (name: {
        name = ".config/opencode/skills/${name}/SKILL.md";
        value.source = "${ponytail}/skills/${name}/SKILL.md";
      }) ponytailSkillNames
    );

  # File mappings for ~/.pi/agent/skills/ - ponytail skills arrive via the
  # pi package (settings.packages), so they are not symlinked here
  piFiles = mkSkillFiles ".pi/agent/skills";
}
