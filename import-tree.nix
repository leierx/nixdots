modulesPath:
let
  recurse =
    dir:
    builtins.concatLists (
      builtins.map (
        name:
        let
          type = (builtins.readDir dir).${name};
          path = dir + "/${name}";
        in
        if builtins.substring 0 1 name == "_" then
          [ ]
        else if type == "directory" then
          recurse path
        else if type == "regular" && builtins.match ".*\\.nix$" name != null then
          [ path ]
        else
          [ ]
      ) (builtins.attrNames (builtins.readDir dir))
    );
in
{
  imports = recurse modulesPath;
}
