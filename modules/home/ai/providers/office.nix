{ lib, ... }:
let
  # Shared Juspay provider data — consumed by both opencode and pi.
  juspay = {
    baseUrl = "https://grid.ai.juspay.net";
    apiKeyEnv = "JUSPAY_API_KEY";
    timeout = 600000;
  };

  modelNames = [
    "open-large"
    "open-fast"
    "open-vision"
    "claude-opus-4-5"
    "claude-opus-4-6"
    "claude-sonnet-4-6"
    "claude-sonnet-4-5"
    "glm-flash-experimental"
    "gemini-3-pro-preview"
    "gemini-3-flash-preview"
    "minimax-m2"
    "glm-latest"
    "kimi-latest"
  ];

  # Opencode format: { name, modalities } per model.
  opencodeJuspayModels = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair name {
        inherit name;
        modalities = {
          input = [
            "text"
            "image"
          ];
          output = [ "text" ];
        };
      }
    ) modelNames
  );

  # Pi format: flat list of { id }.
  piJuspayModels = map (name: { id = name; }) modelNames;
  defaultModel = "litellm/glm-latest";
in
{
  programs.opencode.settings = {
    model = defaultModel;

    provider.litellm = {
      npm = "@ai-sdk/openai-compatible";
      name = "Juspay";
      options = {
        baseURL = juspay.baseUrl;
        apiKey = "{env:JUSPAY_API_KEY}";
        timeout = juspay.timeout;
      };
      models = opencodeJuspayModels;
    };
  };

  programs.pi-coding-agent.models.providers.juspay = {
    baseUrl = juspay.baseUrl;
    api = "openai-completions";
    apiKey = juspay.apiKeyEnv;
    models = piJuspayModels;
  };
}
