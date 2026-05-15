{
  flake.modules.homeManager.wofi =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.wofi ];

      wayland.windowManager.hyprland.settings.layerrule = [ "dimaround, launcher" ];

      programs.wofi = {
        enable = true;

        settings = {
          width = "40%";
          lines = 7;
          prompt = "";
          no_actions = true;
          insensitive = true;
          allow_images = true;
          hide_scroll = true;
          use_search_box = false;
        };

        style = ''
          @define-color fg #f1f1f1;
          @define-color bg1 #1C1C1C;
          @define-color bg2 #2F2F2F;
          @define-color bg3 #3A3A3A;
          @define-color bg4 #474747;
          @define-color bg5 #515151;
          @define-color blue #0E66D0;
          @define-color blueLight #0875F6;
          @define-color green #2BBF3E;
          @define-color red #F13A31;
          @define-color yellow #F1C50F;

          #window {
            all: unset;
            background: rgba(0, 0, 0, 0);
            border-radius: 20pt;
          }

          #input {
            background-color: transparent;
            color: @fg;
            border: none;
            box-shadow: none;
            outline: none;
            padding: 4pt 2pt;
            margin-bottom: 8pt;
            font-size: 13pt;
          }

          #inner-box { all: unset; }

          #outer-box {
            all: unset;
            background: @bg1;
            padding: 15pt;
            border-radius: 20pt;
            border: 1pt solid black;
          }

          #entry {
            padding: 5pt 8pt;
            border-radius: 6pt;
            color: @fg;
          }

          #entry:selected {
            background-color: @blue;
            color: @fg;
          }

          #text {
            color: @fg;
            font-size: 13pt;
          }

          #img {
            min-width: 40pt;
            min-height: 40pt;
          }
        '';
      };
    };
}
