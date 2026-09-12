{
  flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        jq
        fzf
        fastfetch
        tree
      ];
    };
}
