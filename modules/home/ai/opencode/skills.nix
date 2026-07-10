# Skills wiring — maps skill sources to ~/.config/opencode/skills/.
# Sources: local (./skills/), ponytail (vendored), external (claude-code).
{
  inputs,
  lib,
  ...
}:
let
  ponytail = inputs.ponytail;
  claude-code = inputs.claude-code;

  skillsDir = ../skills;
  skillsEntries = builtins.readDir skillsDir;
  ponytailSkillsDir = ponytail + "/skills";
  ponytailSkillsEntries = builtins.readDir ponytailSkillsDir;

  isPonytailSkillDir =
    name:
    ponytailSkillsEntries.${name} == "directory"
    && builtins.pathExists (ponytailSkillsDir + "/${name}/SKILL.md");

  localSkillNames = lib.filter (name: skillsEntries.${name} == "directory") (
    lib.attrNames skillsEntries
  );

  ponytailSkillNames = lib.filter isPonytailSkillDir (lib.attrNames ponytailSkillsEntries);
in
{
  # Skill name list for the agent config
  skills = localSkillNames ++ ponytailSkillNames;

  # File mappings for ~/.config/opencode/skills/
  files =
    let
      local = lib.mapAttrs' (name: _: {
        name = ".config/opencode/skills/${name}/SKILL.md";
        value.source = "${skillsDir}/${name}/SKILL.md";
      }) (lib.filterAttrs (_: type: type == "directory") skillsEntries);

      pony = lib.listToAttrs (
        map (name: {
          name = ".config/opencode/skills/${name}/SKILL.md";
          value.source = "${ponytail}/skills/${name}/SKILL.md";
        }) ponytailSkillNames
      );

      external = {
        ".config/opencode/skills/frontend-design/SKILL.md".source =
          "${claude-code}/plugins/frontend-design/skills/frontend-design/SKILL.md";
      };
    in
    local // pony // external;
}
