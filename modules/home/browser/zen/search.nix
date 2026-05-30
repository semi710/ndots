{ ... }:
{
  programs.zen-browser.profiles.default.search = {
    force = true;
    default = "ddg";
    privateDefault = "ddg";
    engines = {
      "google".metaData.hidden = true;
      "bing".metaData.hidden = true;
      "amazondotcom-us".metaData.hidden = true;
      "ebay".metaData.hidden = true;
      "nix-packages" = {
        name = "Nix Packages";
        urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
        icon = "https://nixos.org/favicon.ico";
        definedAliases = [
          "@np"
          "@nixpkg"
        ];
      };
      "nix-options" = {
        name = "Nix Options";
        urls = [ { template = "https://search.nixos.org/options?query={searchTerms}"; } ];
        definedAliases = [
          "@no"
          "@nixopt"
        ];
      };
      "home-manager" = {
        name = "Home Manager Options";
        urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
        definedAliases = [
          "@hm"
          "@home"
        ];
      };
      "github" = {
        name = "GitHub";
        urls = [ { template = "https://github.com/search?q={searchTerms}&type=repositories"; } ];
        definedAliases = [ "@gh" ];
      };
      "google" = {
        name = "Google";
        urls = [ { template = "https://www.google.com/search?q={searchTerms}"; } ];
        icon = "https://www.google.com/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = [ "@g" ];
      };
    };
  };
}
