{ config, pkgs, lib, ... }:
let
  theme = config.dots.theme;
  cfg = config.dots.gui.apps.footTerminal;
in
{
  options.dots.gui.apps.footTerminal.enable = lib.mkEnableOption "";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.hack-font ];

    home-manager.sharedModules = [
      ({
        programs.foot = {
          enable = true;
          server.enable = false;
          settings = {
            main = {
              term = "xterm-256color";
              font = "Hack:size=16";
              resize-by-cells = "no";
              locked-title = "yes";
              utmp-helper = "none";
            };

            scrollback = {
              lines = 690000;
              multiplier = 3.0;
            };

            key-bindings = {
              scrollback-up-half-page = "Shift+Page_Up";
              scrollback-down-half-page = "Shift+Page_Down";
              clipboard-copy = "Control+Shift+c XF86Copy";
              clipboard-paste = "Control+Shift+v XF86Paste";
              font-increase = "Control+plus";
              font-decrease = "Control+minus";
              font-reset = "Control+0";

              # disabled default bindings
              scrollback-up-page = "none";
              scrollback-down-page = "none";
              primary-paste = "none";
              spawn-terminal = "none";
              search-start = "none";
              show-urls-launch = "none";
              prompt-prev = "none";
              prompt-next = "none";
              unicode-input = "none";
            };

            mouse-bindings = {
              selection-override-modifiers = "Shift";
              scrollback-up-mouse = "BTN_WHEEL_BACK";
              scrollback-down-mouse = "BTN_WHEEL_FORWARD";
              select-begin = "BTN_LEFT";
              select-begin-block = "Control+Shift+BTN_LEFT";
              select-word = "BTN_LEFT-2";
              select-word-whitespace = "Control+BTN_LEFT-2";
              select-quote = "BTN_LEFT-3";
              select-row = "BTN_LEFT-4";
              select-extend = "BTN_RIGHT";
              select-extend-character-wise = "Control+BTN_RIGHT";
              primary-paste = "BTN_MIDDLE";
              font-increase = "none";
              font-decrease = "none";
            };

            colors = {
              background = "${lib.removePrefix "#" theme.bg1}"; # Background color
              foreground = "${lib.removePrefix "#" theme.fg}"; # Foreground color

              alpha = "1.0"; # Transparency level (1.0 = fully opaque)

              regular0 = "${lib.removePrefix "#" theme.black}"; # Black
              regular1 = "${lib.removePrefix "#" theme.red}"; # Red
              regular2 = "${lib.removePrefix "#" theme.green}"; # Green
              regular3 = "${lib.removePrefix "#" theme.yellow}"; # Yellow
              regular4 = "${lib.removePrefix "#" theme.blue}"; # Blue
              regular5 = "${lib.removePrefix "#" theme.magenta}"; # Magenta
              regular6 = "${lib.removePrefix "#" theme.cyan}"; # Cyan
              regular7 = "${lib.removePrefix "#" theme.white}"; # White

              bright0 = "${lib.removePrefix "#" theme.blackLight}"; # Bright black
              bright1 = "${lib.removePrefix "#" theme.redLight}"; # Bright red
              bright2 = "${lib.removePrefix "#" theme.greenLight}"; # Bright green
              bright3 = "${lib.removePrefix "#" theme.yellowLight}"; # Bright yellow
              bright4 = "${lib.removePrefix "#" theme.blueLight}"; # Bright blue
              bright5 = "${lib.removePrefix "#" theme.magentaLight}"; # Bright magenta
              bright6 = "${lib.removePrefix "#" theme.cyanLight}"; # Bright cyan
              bright7 = "${lib.removePrefix "#" theme.whiteLight}"; # Bright white
            };
          };
        };
      })
    ];
  };
}
