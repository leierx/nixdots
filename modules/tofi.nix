{
  flake.modules.homeManager.tofi =
    let
      fg = "#f1f1f1";
      focusedBorderColor = "#0E66D0";
      bg1 = "#1C1C1C";
      bg2 = "#2F2F2F";
      bg3 = "#3A3A3A";
      bg4 = "#474747";
      bg5 = "#515151";
      black = "#1e1e1e";
      blackLight = "#323232";
      blue = "#0E66D0";
      blueLight = "#0875F6";
      cyan = "#4BB0E3";
      cyanLight = "#4FC0F7";
      gray = "#818589";
      grayLight = "#A3A6AA";
      green = "#2BBF3E";
      greenLight = "#2DD042";
      magenta = "#9C48CC";
      magentaLight = "#B24FEA";
      primaryColor = "#0E66D0";
      red = "#F13A31";
      redLight = "#FE3C33";
      unfocusedBorderColor = "#595959";
      white = "#F1F1F1";
      whiteLight = "#FEFEFE";
      yellow = "#F1C50F";
      yellowLight = "#FECF0F";
    in
    {
      programs.tofi = {
        enable = true;
        settings = {
          # Hide the mouse cursor. Default: false
          hide-cursor = true;
          # Show a text cursor in the input field. Default: false
          text-cursor = true;
          # Sort results by number of usages. Default: true
          history = false;
          # Alternate file to read/store history. Default: mode-dependent
          # history-file = "";

          # Matching algorithm: normal|prefix|fuzzy. Default: normal
          # matching-algorithm = "fuzzy";
          # [ERROR]: /home/leier/.config/tofi/config: line 24: Unknown option "matching-algorithm"

          # Require a match to allow a selection. Default: true
          # require-match = true;

          # Automatically accept a result if it's the only one remaining. Default: false
          # auto-accept-single = false;

          # Hide typed input. Default: false
          # hide-input = false;

          # Character to replace displayed input with when hide-input is true. Default: *
          # hidden-character = "*";

          # Use physical keys for shortcuts regardless of keyboard layout. Default: true
          # physical-keybindings = true;

          # Print the 1-based index of the selection instead of the entry. Default: false
          # print-index = false;

          # Directly launch applications on selection in drun mode. Default: false
          drun-launch = true;
          # Terminal to run terminal programs in (drun mode). Default: $TERMINAL
          terminal = "wezterm";

          # Delay keyboard initialisation until after first draw (experimental). Default: false
          # late-keyboard-init = false;

          # Allow multiple simultaneous tofi processes. Default: false
          # multi-instance = false;

          # Assume input is plain ASCII; disables some Unicode handling. Default: false
          ascii-input = true;

          # Font to use (path to font file, or Pango font name). Default: "Sans"
          # font = "Sans";

          # Point size of text. Default: 24
          # font-size = 24;

          # Comma separated OpenType font feature settings. Default: ""
          # font-features = "";

          # Comma separated OpenType font variation settings. Default: ""
          # font-variations = "";

          # Color of the background. Default: #1B1D1E
          background-color = bg1;
          # Width of the border outlines. Default: 4
          outline-width = 0;
          # Color of the border outlines. Default: #080800
          # outline-color = "#080800";
          # Width of the border. Default: 12
          border-width = 25;
          # Color of the border. Default: #F92672
          border-color = bg1;
          # Color of text. Default: #FFFFFF
          text-color = fg;
          # Prompt text. Default: "run: "
          prompt-text = "❯ ";
          # Extra horizontal padding between prompt and input. Default: 0
          prompt-padding = 25;
          # Color of prompt text. Default: same as text-color
          prompt-color = fg;

          # Background color of prompt. Default: #00000000
          # prompt-background = "#00000000";
          # Extra padding of the prompt background (directional). Default: 0
          # prompt-background-padding = 0;
          # Corner radius of the prompt background. Default: 0
          # prompt-background-corner-radius = 0;
          # Placeholder input text. Default: ""
          # placeholder-text = "";
          # Color of placeholder input text. Default: #FFFFFFA8
          # placeholder-color = "#FFFFFFA8";
          # Background color of placeholder input text. Default: #00000000
          # placeholder-background = "#00000000";
          # Extra padding of the placeholder input background (directional). Default: 0
          # placeholder-background-padding = 0;
          # Corner radius of the placeholder input background. Default: 0
          # placeholder-background-corner-radius = 0;
          # Color of input text. Default: same as text-color
          # input-color = "#FFFFFF";
          # Background color of input. Default: #00000000
          # input-background = "#00000000";
          # Extra padding of the input background (directional). Default: 0
          input-background-padding = 0;
          # Corner radius of the input background. Default: 0
          input-background-corner-radius = 0;
          # Style of the text cursor: bar|block|underscore. Default: bar
          text-cursor-style = "bar";
          # Color of the text cursor. Default: same as input-color
          text-cursor-color = "#FFFFFF";
          # Color of text behind block-style text cursor. Default: same as background-color
          text-cursor-background = "#1B1D1E";
          # Corner radius of the text cursor. Default: 0
          text-cursor-corner-radius = 0;
          # Thickness of bar/underscore text cursors. Default: 2 (font-dependent for underscore)
          text-cursor-thickness = 2;
          # Default color of result text. Default: same as text-color
          default-result-color = "#FFFFFF";
          # Default background color of results. Default: #00000000
          default-result-background = "#00000000";
          # Default extra padding of result backgrounds (directional). Default: 0
          default-result-background-padding = 0;
          # Default corner radius of result backgrounds. Default: 0
          default-result-background-corner-radius = 0;
          # Color of alternate (even) result text. Default: same as default-result-color
          alternate-result-color = "#FFFFFF";
          # Background color of alternate (even) results. Default: same as default-result-background
          alternate-result-background = "#00000000";
          # Extra padding of alternate result backgrounds (directional). Default: same as default
          alternate-result-background-padding = 0;
          # Corner radius of alternate result backgrounds. Default: same as default
          alternate-result-background-corner-radius = 0;
          # Maximum number of results to display (0 = fit window). Default: 0
          num-results = 7;
          # Color of selected result. Default: #F92672
          selection-color = "#F92672";
          # Color of the matching portion of the selected result. Default: #00000000
          selection-match-color = "#00000000";
          # Background color of selected result. Default: #00000000
          selection-background = "#00000000";
          # Extra padding of the selected result background (directional). Default: 0
          selection-background-padding = 0;
          # Corner radius of the selected result background. Default: 0
          selection-background-corner-radius = 0;
          # Spacing between results (can be negative). Default: 0
          result-spacing = 0;
          # Minimum width of input in horizontal mode. Default: 0
          min-input-width = 0;
          # Width of the window (px or %). Default: 1280
          # width = 300;
          # Height of the window (px or %). Default: 720
          # height = 350;
          # Radius of the window corners. Default: 0
          corner-radius = 0;

          # Window anchor: top-left|top|top-right|right|bottom-right|bottom|bottom-left|left|center. Default: center
          # anchor = "center";

          # Exclusive zone size (-1 ignores, 0 avoids, >0 sets). Default: -1
          # exclusive-zone = -1;
          # Name of the output to appear on. Default: ""
          # output = "";
          # Scale the window by the output's scale factor. Default: true
          # scale = true;
          # Offset from top of screen (px or %). Default: 0
          # margin-top = 0;
          # Offset from bottom of screen (px or %). Default: 0
          # margin-bottom = 0;
          # Offset from left of screen (px or %). Default: 0
          # margin-left = 0;
          # Offset from right of screen (px or %). Default: 0
          # margin-right = 0;

          # Padding between top border and text (px or %). Default: 8
          padding-top = 0;
          # Padding between bottom border and text (px or %). Default: 8
          padding-bottom = 0;
          # Padding between left border and text (px or %). Default: 8
          padding-left = "2%";
          # Padding between right border and text (px or %). Default: 8
          padding-right = 0;

          # Clip text drawing to within the specified padding. Default: true
          # clip-to-padding = true;

          # List results horizontally. Default: false
          # horizontal = false;

          # Perform font hinting (only with font file path). Default: true
          # hint-font = true;
        };
      };
    };
}
