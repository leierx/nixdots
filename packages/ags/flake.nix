{
  outputs =
    { ags, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
        name = "ags-shell";
        src = ./.;

        nativeBuildInputs = with pkgs; [
          wrapGAppsHook3
          gobject-introspection
          ags.packages.x86_64-linux.default
        ];

        buildInputs =
          with ags.packages.x86_64-linux;
          [
            astal4
            battery
            hyprland
            notifd
            tray
          ]
          ++ [ pkgs.gjs ];

        installPhase = ''
          mkdir -p $out/bin
          ags bundle app.tsx $out/bin/ags-shell
        '';
      };
    };

  inputs = {
    ags.url = "github:aylur/ags?ref=v3.1.1";
    nixpkgs.follows = "ags/nixpkgs";
  };
}
