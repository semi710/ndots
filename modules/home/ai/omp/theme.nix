{
  lib,
  omp,
  palette,
}:
let
  hex = c: "#" + palette.${c};

  # The nerd preset's icon.context is the Windows logo (\ue70f); overriding it
  # per-theme is the only supported symbol override path.
  boxIcon = {
    symbols.overrides."icon.context" = "◫";
  };

  # Full role mapping of omp's 66 color slots onto the 16 base16 colors, so
  # any stylix scheme drives the theme. Bg slots use plain palette keys (no
  # tinting) to keep the mapping scheme-generic.
  darkColors = {
    accent = hex "base0D";
    border = hex "base02";
    borderAccent = hex "base0D";
    borderMuted = hex "base01";
    success = hex "base0B";
    error = hex "base08";
    warning = hex "base0A";
    muted = hex "base04";
    dim = hex "base03";
    text = "";
    thinkingText = hex "base04";
    selectedBg = hex "base02";
    userMessageBg = hex "base01";
    userMessageText = "";
    customMessageBg = hex "base02";
    customMessageText = "";
    customMessageLabel = hex "base0E";
    toolPendingBg = hex "base01";
    toolSuccessBg = hex "base01";
    toolErrorBg = hex "base01";
    toolTitle = "";
    toolOutput = hex "base04";
    mdHeading = hex "base0D";
    mdLink = hex "base0D";
    mdLinkUrl = hex "base0C";
    mdCode = hex "base0B";
    mdCodeBlock = hex "base04";
    mdCodeBlockBorder = hex "base02";
    mdQuote = hex "base04";
    mdQuoteBorder = hex "base02";
    mdHr = hex "base02";
    mdListBullet = hex "base0D";
    toolDiffAdded = hex "base0B";
    toolDiffRemoved = hex "base08";
    toolDiffContext = hex "base04";
    syntaxComment = hex "base03";
    syntaxKeyword = hex "base0D";
    syntaxFunction = hex "base0B";
    syntaxVariable = hex "base06";
    syntaxString = hex "base0A";
    syntaxNumber = hex "base09";
    syntaxType = hex "base0D";
    syntaxOperator = hex "base0D";
    syntaxPunctuation = hex "base04";
    thinkingOff = hex "base01";
    thinkingMinimal = hex "base02";
    thinkingLow = hex "base03";
    thinkingMedium = hex "base04";
    thinkingHigh = hex "base0D";
    thinkingXhigh = hex "base0E";
    bashMode = hex "base0B";
    statusLineBg = hex "base01";
    statusLineSep = hex "base02";
    statusLineModel = hex "base0D";
    statusLinePath = hex "base06";
    statusLineGitClean = hex "base0B";
    statusLineGitDirty = hex "base0A";
    statusLineContext = hex "base04";
    statusLineSpend = hex "base09";
    statusLineStaged = hex "base0B";
    statusLineDirty = hex "base0A";
    statusLineUntracked = hex "base04";
    statusLineOutput = hex "base0C";
    statusLineCost = hex "base09";
    statusLineSubagents = hex "base0D";
    pythonMode = hex "base0A";
  };
in
{
  dark = {
    name = "ndots-dark";
    colors = darkColors;
  }
  // boxIcon;

  # Stylix polarity is dark, so the light theme never renders; keep it
  # upstream-derived (base16-schemes has no kanagawa light variant anyway).
  light =
    lib.recursiveUpdate
      (builtins.fromJSON (builtins.readFile "${omp}/packages/coding-agent/src/modes/theme/light.json"))
      {
        name = "ndots-light";
        symbols.overrides."icon.context" = "◫";
      };
}
