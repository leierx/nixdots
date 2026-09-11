# Template for standalone home-manager on a non-NixOS box
{
  hosts.example-home = {
    class = "home";
    user = "leier";
    bundles = [ "minimal" ];
  };
}
