{ inputs, pkgs, ... }:
let
  firefox-addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.zen-browser.profiles.default = {
    # Acknowledge that extensions.settings will override all previous extension settings
    extensions.force = true;

    # Extensions managed via rycee/firefox-addons
    extensions.packages = with firefox-addons; [
      ublock-origin
      darkreader
      simple-translate
      firenvim
      auto-tab-discard
      duckduckgo-privacy-essentials
      vimium
      zen-internet
      refined-github
    ];

    # Extension settings (via storage.local)
    extensions.settings = {
      "addon@darkreader.org".settings = {
        syncSettings = true;
        previewNewDesign = true;
      };
    };
  };

  # Extensions not in rycee — installed via AMO policies
  programs.zen-browser.policies.ExtensionSettings = {
    # iCloud Passwords
    "password-manager-firefox-extension@apple.com" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/icloud-passwords/latest.xpi";
      installation_mode = "normal_installed";
    };
    # Material Icons for GitHub
    "{eac6e624-97fa-4f28-9d24-c06c9b8aa713}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/material-icons-for-github/latest.xpi";
      installation_mode = "normal_installed";
    };
    # GitOwl
    "gitowl@gitowl.dev" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/gitowl/latest.xpi";
      installation_mode = "normal_installed";
    };
    # Nixpkgs PR Tracker
    "nixpkgs-pr-tracker@tahayassine.me" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/nixpkgs-pr-tracker/latest.xpi";
      installation_mode = "normal_installed";
    };
    # LanguageTool (unfree license — not in rycee)
    "languagetool-webextension@languagetool.org" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/languagetool-grammar-checker/latest.xpi";
      installation_mode = "normal_installed";
    };
    # Wide GitHub
    "{72742915-c83b-4485-9023-b55dc5a1e730}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/widegithub/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
}
