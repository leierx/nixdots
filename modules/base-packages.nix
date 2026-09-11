{
  flake.modules.nixos.base-packages =
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
