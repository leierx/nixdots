{
  flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
      environment.systemPackages = with pkgs; [
        jq
        fzf
        fastfetch
        tree
      ];
    };
}
