# Template for a nix-darwin machine; rename and flesh out when adding a real mac
{ config, ... }:
{
  darwinHosts.example-mac = { };

  flake.modules.darwin."darwinConfigurations/example-mac".imports =
    with config.flake.modules.darwin; [ base ];
}
