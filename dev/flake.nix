{
  description = "quickshell experiments (isolated from the main flake)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    qs = pkgs.quickshell;
    iconThemes = [ pkgs.adwaita-icon-theme pkgs.networkmanagerapplet ];
    iconEnv = pkgs.lib.concatMapStringsSep ":" (t: "${t}/share") iconThemes;
    qtStyle = pkgs.adwaita-qt6;
    config = ./quickshell;
    themeEnv = ''
      export XDG_DATA_DIRS="${iconEnv}:''${XDG_DATA_DIRS:-}"
      export QT_STYLE_OVERRIDE=adwaita-dark
      export QT_PLUGIN_PATH="${qtStyle}/lib/qt-6/plugins:''${QT_PLUGIN_PATH:-}"
    '';
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ qs ] ++ iconThemes ++ [ qtStyle ];
      shellHook = themeEnv;
    };

    packages.${system}.default = pkgs.writeShellScriptBin "qshell" ''
      ${themeEnv}
      exec ${qs}/bin/quickshell -p ${config}/shell.qml
    '';

    apps.${system}.default = {
      type = "app";
      program = "${self.packages.${system}.default}/bin/qshell";
    };
  };
}