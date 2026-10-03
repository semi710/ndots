# Skills wiring - maps skill sources to ~/.config/opencode/skills/.
# Sources: local (./skills/), workmux (flake), external (claude-code).
# Ponytail skills are NOT symlinked here: the ponytail plugin registers its
# own skills dir via config.skills.paths, so symlinking them too
# double-registered every skill and warned on every boot.
{
  inputs,
  lib,
  ...
}:
let
  claude-code = inputs.claude-code;
  workmux = inputs.workmux;
  ponytail = inputs.ponytail;

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
      # ship every file in a skill dir (SKILL.md plus references like checklists/templates)
      local = lib.listToAttrs (
        lib.concatMap (
          name:
          map (f: {
            name = "${prefix}/${name}/${f}";
            value.source = "${skillsDir}/${name}/${f}";
          }) (builtins.attrNames (builtins.readDir "${skillsDir}/${name}"))
        ) (lib.filter (name: skillsEntries.${name} == "directory") (lib.attrNames skillsEntries))
      );

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

  # Eval-time skill hygiene, ported from agent-scripts' validate-skills:
  # authored skills must open with a front-matter fence on line 1, close it,
  # and carry non-empty name + description. Input-provided skills only get
  # the duplicate-name check below, so upstream breakage cannot wedge eval.
  frontMatterLines =
    text:
    let
      lines = map (l: lib.removeSuffix "\r" l) (lib.splitString "\n" text);
      body = lib.tail lines;
      fenceIdx = lib.lists.findFirstIndex (l: lib.hasPrefix "---" l) (-1) body;
    in
    if lib.head lines != "---" || fenceIdx < 0 then null else lib.take fenceIdx body;

  hasField = fm: field: lib.any (l: lib.match "${field}:[[:space:]]*[^[:space:]].*" l != null) fm;

  localSkillError =
    name:
    let
      fm = frontMatterLines (builtins.readFile "${skillsDir}/${name}/SKILL.md");
    in
    if fm == null then
      "front matter fence missing or unclosed"
    else if !hasField fm "name" then
      "missing non-empty name field"
    else if !hasField fm "description" then
      "missing non-empty description field"
    else
      null;

  badLocalSkills = lib.filter (name: localSkillError name != null) localSkillNames;

  # local + workmux are symlinked by us, ponytail loads via its plugin - all
  # three land in opencode's skill list, so their names must not collide
  loadedSkillNames = localSkillNames ++ workmuxSkillNames ++ ponytailSkillNames;
  duplicatedSkillName = lib.findFirst (
    n: lib.count (x: x == n) loadedSkillNames > 1
  ) null loadedSkillNames;
in
lib.throwIf (badLocalSkills != [ ])
  "skills with invalid SKILL.md front matter: ${toString badLocalSkills}"
  (
    lib.throwIf (duplicatedSkillName != null)
      "duplicate skill name across sources: ${toString duplicatedSkillName}"
      {
        # File mappings for ~/.config/opencode/skills/
        files = mkSkillFiles ".config/opencode/skills";

        # File mappings for ~/.pi/agent/skills/ - ponytail skills arrive via
        # the pi package (settings.packages), so they are not symlinked here
        piFiles = mkSkillFiles ".pi/agent/skills";
      }
  )
