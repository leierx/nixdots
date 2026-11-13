{
  description = "quickshell experiments (isolated from the main flake)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # shell.qml asks for Papirus-Dark by name
      iconEnv = ''export XDG_DATA_DIRS="${pkgs.papirus-icon-theme}/share:''${XDG_DATA_DIRS:-}"'';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.quickshell ];
        shellHook = iconEnv;
      };

      packages.${system}.default = pkgs.writeShellScriptBin "qshell" ''
        ${iconEnv}
        exec ${pkgs.quickshell}/bin/quickshell -p ${./quickshell}
      '';
    };
}
