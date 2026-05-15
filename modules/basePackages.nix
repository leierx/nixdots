{
  flake.modules.nixos.basePackages =
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
