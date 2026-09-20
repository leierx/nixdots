# Turns a directory into a module importing every `.nix` beneath it; `.`/`_`
# prefixed paths are skipped, so `_` can hold non-module Nix code.
modulesPath:
let
  isHidden = name: builtins.substring 0 1 name == "." || builtins.substring 0 1 name == "_";

  isNixFile = name: builtins.match ".*\\.nix$" name != null;

  recurse =
    dir:
    let
      entries = builtins.readDir dir;
      visible = builtins.filter (name: !isHidden name) (builtins.attrNames entries);
    in
    builtins.concatLists (
      builtins.map (
        name:
        let
          path = dir + "/${name}";
        in
        if entries.${name} == "directory" then
          recurse path
        else if entries.${name} == "regular" && isNixFile name then
          [ path ]
        else
          [ ]
      ) visible
    );
in
{
  imports = recurse modulesPath;
}
