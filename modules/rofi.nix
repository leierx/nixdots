{
  modules.homeManager.rofi =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.hack-font
        pkgs.papirus-icon-theme
      ];

      programs.rofi = {
        enable = true;
        font = "Hack 16";
        cycle = false;
        terminal = "wezterm";
        extraConfig = {
          show-icons = true;
          drun-match-fields = "name,exec,generic,categories,keywords";
          drun-display-format = "{name}";
          disable-history = true;
          sort = true;
          sorting-method = "fzf";
        };
        theme = builtins.toFile "rofi-theme.rasi" ''
          * {
            fg: #f1f1f1;
            focusedBorderColor: #0E66D0;
            unfocusedBorderColor: #595959;
            bg1: #1C1C1C;
            bg2: #2F2F2F;
            bg3: #3A3A3A;
            bg4: #474747;
            bg5: #515151;
            black: #1e1e1e;
            blackLight: #323232;
            blue: #0E66D0;
            blueLight: #0875F6;
            cyan: #4BB0E3;
            cyanLight: #4FC0F7;
            gray: #818589;
            grayLight: #A3A6AA;
            green: #2BBF3E;
            greenLight: #2DD042;
            magenta: #9C48CC;
            magentaLight: #B24FEA;
            primaryColor: #0E66D0;
            red: #F13A31;
            redLight: #FE3C33;
            white: #F1F1F1;
            whiteLight: #FEFEFE;
            yellow: #F1C50F;
            yellowLight: #FECF0F;
            // standard names
            foreground: @fg;
            background: @bg1;

            active-background: @background;
            active-foreground: @foreground;
            normal-background: @background;
            normal-foreground: @foreground;
            urgent-background: @background;
            urgent-foreground: @foreground;

            alternate-active-background: @active-background;
            alternate-active-foreground: @active-foreground;
            alternate-normal-background: @normal-background;
            alternate-normal-foreground: @normal-foreground;
            alternate-urgent-background: @urgent-background;
            alternate-urgent-foreground: @urgent-foreground;

            selected-active-background: @bg3;
            selected-active-foreground: @active-foreground;
            selected-normal-background: @bg3;
            selected-normal-foreground: @normal-foreground;
            selected-urgent-background: @bg3;
            selected-urgent-foreground: @urgent-foreground;

            separatorcolor: @black;
          }

          window {
              background-color: @background;
              padding: 0.75em;
              border: 0.1em;
              border-color: #000;
              border-radius: 0.5em;
              width: 25em;
          }

          mainbox {
              padding: 0;
              border: 0;
              spacing: 0.5em;
              background-color: @background;
          }

          message {
            background-color: transparent;
            padding: 0;
            border: 0.1em;
            border-color: @primaryColor;
            border-radius: 0.5em;
          }

          error-message {
            background-color: transparent;
            padding: 0;
            border: 0.1em;
            border-color: @red;
            border-radius: 0.5em;
          }

          textbox {
              text-color: @foreground;
              padding: 1em;
              border: 0;
              background-color: @selected-normal-background;
          }

          listview {
              padding: 0;
              border: 0;
              spacing: 0;
              scrollbar: false;
              background-color: @background;
              fixed-height: true;
              lines: 7;
          }

          // Disabled above
          scrollbar { enabled: false; }

          mode-switcher {
            border: 0;
            spacing: 0.5em;
            padding: 0;
            background-color: @background;
          }

          button {
              cursor: pointer;
              padding: 0.5em 1em;
              border: 0.1em;
              border-color: transparent;
              border-radius: 0.5em;
              text-color: @normal-foreground;
              background-color: @background;
          }

          button selected {
              border-color: #000;
              background-color: @selected-normal-background;
              text-color: @selected-normal-foreground;
          }

          case-indicator { enabled: false; }
          num-filtered-rows { enabled: false; }
          num-rows { enabled: false; }
          overlay { enabled: false; }
          prompt { enabled: false; }
          textbox-num-sep { enabled: false; }
          textbox-prompt-colon { enabled: false; }

          inputbar {
              padding: 0.5em 1em;
              spacing: 0;
              border: 0;
              text-color: @normal-foreground;
              background-color: transparent;
              children: [ "entry" ];
          }

          entry {
              padding: 0;
              text-color: inherit;
              background-color: inherit;
              cursor: text;
              placeholder-color: @gray;
              placeholder: "";
              blink: false;
          }

          element {
              padding: 0.75em;
              cursor: pointer;
              border-radius: 0.5em;
              border: 0;
              spacing: 0.5em;
              highlight: bold underline;
          }

          element normal.normal {
              background-color: @normal-background;
              text-color: @normal-foreground;
          }

          element normal.urgent {
              background-color: @urgent-background;
              text-color: @urgent-foreground;
          }

          element normal.active {
              background-color: @active-background;
              text-color: @active-foreground;
          }

          element selected.normal {
              background-color: @selected-normal-background;
              text-color: @selected-normal-foreground;
          }

          element selected.urgent {
              background-color: @selected-urgent-background;
              text-color: @selected-urgent-foreground;
          }

          element selected.active {
              background-color: @selected-active-background;
              text-color: @selected-active-foreground;
          }

          element alternate.normal {
              background-color: @alternate-normal-background;
              text-color: @alternate-normal-foreground;
          }

          element alternate.urgent {
              background-color: @alternate-urgent-background;
              text-color: @alternate-urgent-foreground;
          }

          element alternate.active {
              background-color: @alternate-active-background;
              text-color: @alternate-active-foreground;
          }

          element-text {
              background-color: transparent;
              cursor: inherit;
              highlight: inherit;
              text-color: inherit;
              vertical-align: 0.50;
          }

          element-icon {
              background-color: transparent;
              size: 1.25em ;
              cursor: inherit;
              text-color: inherit;
          }
        '';
      };
    };
}
