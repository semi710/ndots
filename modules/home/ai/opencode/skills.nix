# Skills wiring — maps skill sources to ~/.config/opencode/skills/.
# Sources: local (./skills/), ponytail (vendored), external (claude-code),
# cybersecurity-skills (817-skill library from mukul975/Anthropic-Cybersecurity-Skills).
{
  inputs,
  lib,
  ...
}:
let
  ponytail = inputs.ponytail;
  claude-code = inputs.claude-code;
  cybersecurity = inputs.cybersecurity-skills;

  skillsDir = ../skills;
  skillsEntries = builtins.readDir skillsDir;
  ponytailSkillsDir = ponytail + "/skills";
  ponytailSkillsEntries = builtins.readDir ponytailSkillsDir;
  cyberSkillsDir = cybersecurity + "/skills";
  cyberSkillsEntries = builtins.readDir cyberSkillsDir;

  isPonytailSkillDir =
    name:
    ponytailSkillsEntries.${name} == "directory"
    && builtins.pathExists (ponytailSkillsDir + "/${name}/SKILL.md");

  isCyberSkillDir =
    name:
    cyberSkillsEntries.${name} == "directory"
    && builtins.pathExists (cyberSkillsDir + "/${name}/SKILL.md");

  localSkillNames = lib.filter (name: skillsEntries.${name} == "directory") (
    lib.attrNames skillsEntries
  );

  ponytailSkillNames = lib.filter isPonytailSkillDir (lib.attrNames ponytailSkillsEntries);
  cyberSkillNames = lib.filter isCyberSkillDir (lib.attrNames cyberSkillsEntries);
in
{
  # Skill name list for the agent config
  skills = localSkillNames ++ ponytailSkillNames ++ cyberSkillNames;

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

      cyber = lib.listToAttrs (
        map (name: {
          name = ".config/opencode/skills/${name}/SKILL.md";
          value.source = "${cyberSkillsDir}/${name}/SKILL.md";
        }) cyberSkillNames
      );
    in
    local // pony // external // cyber;
}
