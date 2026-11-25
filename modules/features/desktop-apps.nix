{
  flake.modules.homeManager.desktop-apps =
    { lib, pkgs, ... }:
    let
      imageViewer = "org.gnome.Loupe.desktop";
      videoPlayer = "io.github.celluloid_player.Celluloid.desktop";
      documentViewer = "org.gnome.Papers.desktop";
      images = [
        "image/apng"
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heic"
        "image/jp2"
        "image/jpeg"
        "image/jxl"
        "image/png"
        "image/qoi"
        "image/svg+xml"
        "image/svg+xml-compressed"
        "image/tiff"
        "image/vnd.microsoft.icon"
        "image/webp"
        "image/x-dds"
        "image/x-exr"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-qoi"
        "image/x-tga"
        "image/x-win-bitmap"
        "image/x-xbitmap"
        "image/x-xpixmap"
      ];
      videos = [
        "application/x-matroska"
        "video/3gpp"
        "video/3gpp2"
        "video/dv"
        "video/mp2t"
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-avi"
        "video/x-flv"
        "video/x-m4v"
        "video/x-matroska"
        "video/x-ms-wmv"
        "video/x-msvideo"
        "video/x-ogm+ogg"
        "video/x-theora+ogg"
      ];
      # Celluloid leaves mpv's hwdec=no, so without this every frame is decoded on the CPU
      mpvConf = pkgs.writeText "celluloid-mpv.conf" ''
        hwdec=auto-safe
        profile=fast
      '';
    in
    {
      home.packages = with pkgs; [
        mousepad
        spotify
        pwvucontrol
        firefox-bin
        obsidian
        discord-canary
        celluloid
        loupe
        papers
      ];

      # below ~/.config/mimeapps.list, which apps write to and an "Open With" choice still overrides
      xdg.dataFile."applications/mimeapps.list".text = lib.generators.toINI { } {
        "Default Applications" =
          lib.genAttrs images (_: imageViewer)
          // lib.genAttrs videos (_: videoPlayer)
          // {
            "application/pdf" = documentViewer;
          };
      };

      dconf.settings."io/github/celluloid-player/celluloid" = {
        mpv-config-enable = true;
        mpv-config-file = "${mpvConf}";
        # hands the video to Hyprland as its own surface instead of GTK compositing it
        graphics-offload-enable = true;
        # reads every file in a playlist before the first one plays
        prefetch-metadata = false;
      };
    };
}
