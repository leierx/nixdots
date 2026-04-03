{
  flake.modules.nixos.basicPackages =
    { pkgs }:
    {
      environment.systemPackages = with pkgs; [
        jq
        fzf
        fastfetch
        tree
      ];
    };
}
