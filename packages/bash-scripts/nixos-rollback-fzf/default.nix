{ pkgs }:

pkgs.writeShellApplication {
  name = "nixos-rollback-fzf";
  meta.platforms = pkgs.lib.platforms.linux;
  runtimeInputs = with pkgs; [
    fzf
    jq
    nix
    coreutils
    util-linux
  ];
  text = builtins.readFile ./nixos-rollback-fzf.sh;
}
