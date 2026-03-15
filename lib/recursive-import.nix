# Recursively imports all *.nix modules in a directory tree (excluding default.nix, flake.nix)
dir:
let
  collect =
    dir:
    let
      entries = builtins.readDir dir;
      entryNames = builtins.attrNames entries;
    in
    builtins.concatMap (
      name:
      let
        path = dir + "/${name}";
        type = entries.${name};
      in
      if type == "directory" then
        collect path
      else if type == "regular" && builtins.match ".*\\.nix" name != null && name != "default.nix" && name != "flake.nix" then
        [ (import path) ]
      else
        [ ]
    ) entryNames;
in
{
  imports = collect dir;
}
