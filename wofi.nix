let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  }) { };

  wofiConfig = pkgs.writeTextDir "share/wofi/config" ''
    width=30%
    lines=7
    prompt=
    no_actions=true
    insensitive=true
    allow_images=true
    hide_scroll=true
    # matching=MODE could be worth looking into.
    use_search_box=false
  '';

  wofiStyle = pkgs.writeTextFile {
    name = "wofi-style.css";
    destination = "/share/wofi/style.css";
    text = ''
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

in
pkgs.mkShell {
  packages = [ pkgs.wofi ];

  # Expose the config/style so wofi picks them up via XDG or explicit flags.
  shellHook = ''
    export WOFI_CONFIG="${wofiConfig}/share/wofi/config"
    export WOFI_STYLE="${wofiStyle}/share/wofi/style.css"

    echo "wofi sandbox ready."
    echo "  wofi --show drun --conf \$WOFI_CONFIG --style \$WOFI_STYLE"
    echo "  wofi --show run  --conf \$WOFI_CONFIG --style \$WOFI_STYLE"
  '';
}
