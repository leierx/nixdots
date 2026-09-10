# Template for standalone home-manager on a non-NixOS box
{
  systems.example-home = {
    class = "home";
    user = "leier";
    bundles = [ "minimal" ];
  };
}
