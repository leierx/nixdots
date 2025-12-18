# import everything in this folder
{ lib, ... }:
{
  imports = lib.filter (path: path != ./default.nix) (
    map (name: ./. + "/${name}") (builtins.attrNames (builtins.readDir ./.))
  );
}
