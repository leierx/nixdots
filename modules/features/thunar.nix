let
  # programs.thunar takes pkgs.thunar, 26.05's 4.20.9; back to it once 26.11 ships
  thunarFor =
    pkgs:
    pkgs.unstable.thunar.override {
      thunarPlugins = with pkgs.unstable; [
        thunar-volman
        thunar-vcs-plugin
      ];
    };
in
{
  flake.modules.nixos.thunar =
    { lib, pkgs, ... }:
    let
      package = thunarFor pkgs;
    in
    {
      environment.systemPackages = [ package ];
      services.dbus.packages = [ package ];
      systemd.packages = [ package ];
      programs.xfconf.enable = true;

      # the daemon from login, so thunar-volman mounts a drive plugged in before any window opens
      systemd.user.services.thunar = {
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        # NixOS' unit PATH would replace the session's, and Thunar opens apps by name
        environment.PATH = lib.mkForce null;
      };

      services.gvfs = {
        enable = true;
        # GNOME's build adds online accounts, the keyring and OneDrive
        package = pkgs.gvfs;
      };
      services.tumbler.enable = true;

      xdg.mime.defaultApplications."inode/directory" = "thunar.desktop";
    };

  flake.modules.homeManager.thunar =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      thunar = lib.getExe' (thunarFor pkgs) "thunar";
      wezterm = lib.getExe config.programs.wezterm.package;
      gio = lib.getExe' pkgs.glib "gio";

      helper = pkgs.writeShellApplication {
        name = "thunar-actions";
        runtimeInputs = [
          pkgs.ouch
          pkgs.wl-clipboard
          pkgs.libnotify
        ];
        text = ''
          action=$1
          shift
          cd -- "$(dirname -- "$1")"
          names=()
          for path; do names+=("$(basename -- "$path")"); done

          fail() {
            notify-send -a Thunar -i dialog-error "$1" "$2"
            exit 1
          }

          case $action in
            copy-paths)
              printf '%s\n' "$@" | wl-copy -n
              ;;
            extract)
              out=$(ouch decompress --no --accessible -- "''${names[@]}" 2>&1) || fail "Extraction Failed" "$out"
              ;;
            compress-*)
              format=''${action#compress-}
              if (($# == 1)); then base=''${names[0]}; else base=$(basename -- "$PWD"); fi
              [[ $base == / ]] && base=Archive
              target=$base.$format
              n=2
              while [[ -e $target ]]; do
                target="$base ($n).$format"
                n=$((n + 1))
              done
              out=$(ouch compress --accessible -- "''${names[@]}" "$target" 2>&1) || fail "Compression Failed" "$out"
              ;;
          esac
        '';
      };
      run = action: "${lib.getExe helper} ${action} %F";

      everything = [
        "directories"
        "audio-files"
        "image-files"
        "other-files"
        "text-files"
        "video-files"
      ];
      archives = lib.concatMapStringsSep ";" (ext: "*.${ext}") [
        "tar"
        "tar.gz"
        "tgz"
        "tar.xz"
        "txz"
        "tar.zst"
        "tzst"
        "tar.bz2"
        "tbz2"
        "tar.lz4"
        "zip"
        "7z"
        "rar"
        "gz"
        "xz"
        "zst"
        "bz2"
        "bz3"
        "lz4"
        "lzma"
        "lz"
        "sz"
        "br"
      ];

      actions = [
        {
          id = "terminal";
          name = "Open Terminal Here";
          icon = "utilities-terminal";
          command = "${wezterm} start --cwd %f";
          types = [ "directories" ];
          key = "F4";
        }
      ]
      ++ lib.optional config.programs.neovim.enable {
        id = "nvim";
        name = "Open in Neovim";
        icon = "nvim";
        command = "${wezterm} start --cwd %d -- ${lib.getExe config.programs.neovim.finalPackage} %F";
        types = [ "text-files" ];
      }
      ++ [
        {
          id = "copy-path";
          name = "Copy Path";
          icon = "edit-copy";
          command = run "copy-paths";
          types = everything;
          key = "<Primary><Shift>c";
        }
        {
          id = "root";
          name = "Open as Root";
          icon = "dialog-password";
          command = "${thunar} admin://%f";
          types = [ "directories" ];
        }
        {
          id = "preview";
          name = "Preview";
          icon = "view-preview";
          command = "${gio} open %f";
          types = [
            "image-files"
            "video-files"
          ];
          key = "space";
        }
        {
          id = "extract";
          name = "Extract Here";
          icon = "archive-extract";
          command = run "extract";
          patterns = archives;
          types = [ "other-files" ];
        }
        {
          id = "compress-tar-zst";
          submenu = "Compress";
          name = "As .tar.zst";
          icon = "archive-insert";
          command = run "compress-tar.zst";
          types = everything;
        }
        {
          id = "compress-zip";
          submenu = "Compress";
          name = "As .zip";
          icon = "archive-insert";
          command = run "compress-zip";
          types = everything;
        }
      ];

      element = name: value: "    <${name}>${lib.escapeXML value}</${name}>\n";
      ucaXml = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <actions>
        ${
          lib.concatMapStrings (
            action:
            "  <action>\n"
            + element "icon" action.icon
            + element "name" action.name
            + element "submenu" (action.submenu or "")
            + element "unique-id" action.id
            + element "command" action.command
            + element "description" ""
            + element "range" ""
            + element "patterns" (action.patterns or "*")
            + lib.concatMapStrings (type: "    <${type}/>\n") action.types
            + "  </action>\n"
          ) actions
        }</actions>
      '';
    in
    {
      xfconf.settings = {
        thunar = {
          misc-use-csd = true;
          last-menubar-visible = false;
          misc-symbolic-icons-in-sidepane = true;
          last-location-bar = "ThunarLocationButtons";
          last-image-preview-visible = true;
          misc-image-preview-mode = "THUNAR_IMAGE_PREVIEW_MODE_EMBEDDED";
        };
        thunar-volman = {
          "automount-drives/enabled" = true;
          "automount-media/enabled" = true;
        };
      };

      xdg.configFile."Thunar/uca.xml".text = ucaXml;
      xdg.configFile."Thunar/accels.scm".text = lib.concatMapStrings (
        action:
        lib.optionalString (
          action ? key
        ) "(gtk_accel_path \"<Actions>/ThunarActions/uca-action-${action.id}\" \"${action.key}\")\n"
      ) actions;
    };
}
