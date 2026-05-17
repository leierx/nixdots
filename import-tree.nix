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
        if builtins.match "^_.*" name != null then
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
