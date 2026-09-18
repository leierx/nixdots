root: {
  flake.modules.homeManager.pi-agent =
    { pkgs, ... }:
    {
      home.file.".pi/agent/themes/adwaita_darker.json".source =
        (pkgs.formats.json { }).generate "pi-theme-adwaita_darker.json"
          {
            "$schema" =
              "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
            name = "adwaita_darker";
            vars = root.config.palettes.adwaita_darker;
            colors = {
              accent = "color4";
              border = "color4";
              borderAccent = "color6";
              borderMuted = "color8";
              success = "color2";
              error = "color1";
              warning = "color3";
              muted = "color8";
              dim = "color8";
              text = "foreground";
              thinkingText = "color8";
              scrollbarTrack = "inactive_border_color";
              scrollbarThumb = "color8";

              selectedBg = "selection_background";
              searchMatchBg = "selection_background";
              searchMatchText = "selection_foreground";
              userMessageBg = "selection_background";
              userMessageText = "foreground";
              customMessageBg = "active_border_color";
              customMessageText = "foreground";
              customMessageLabel = "color5";
              toolPendingBg = "active_border_color";
              toolSuccessBg = "active_border_color";
              toolErrorBg = "active_border_color";
              toolTitle = "foreground";
              toolOutput = "color8";

              mdHeading = "color3";
              mdLink = "color4";
              mdLinkUrl = "color8";
              mdCode = "color6";
              mdCodeBlock = "color2";
              mdCodeBlockBorder = "color8";
              mdQuote = "color8";
              mdQuoteBorder = "color8";
              mdHr = "color8";
              mdListBullet = "color6";

              toolDiffAdded = "color2";
              toolDiffRemoved = "color1";
              toolDiffContext = "color8";

              syntaxComment = "color8";
              syntaxKeyword = "color4";
              syntaxFunction = "color3";
              syntaxVariable = "color6";
              syntaxString = "color2";
              syntaxNumber = "color5";
              syntaxType = "color6";
              syntaxOperator = "foreground";
              syntaxPunctuation = "foreground";

              thinkingOff = "color8";
              thinkingMinimal = "color8";
              thinkingLow = "color4";
              thinkingMedium = "color6";
              thinkingHigh = "color5";
              thinkingXhigh = "color1";
              thinkingMax = "color13";

              bashMode = "color3";
            };
            export = {
              pageBg = "background";
              cardBg = "selection_background";
              infoBg = "active_border_color";
            };
          };
    };
}
