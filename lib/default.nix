{ lib, ... }:
let
  inherit (builtins) map attrNames getAttr hasAttr listToAttrs readDir;
  inherit (lib) flatten;
in rec {
  packageNames = dir:
    attrNames (
      lib.filterAttrs (k: v: v == "directory") (readDir dir)
    );

  forEachDir = f: dir:
    map (x: f dir x) (packageNames dir);

  importPackageAsAttr = dir: name: args:
  let
    imported = import (dir + "/${name}") args;
  in
    if hasAttr "drvPath" imported
    then [ { name = name; value = imported; } ]
    else map (x: { name = x; value = (getAttr x imported); }) (attrNames imported);

  mkPackages = dir: args:
    listToAttrs (
      flatten (forEachDir (dir: name: importPackageAsAttr dir name args) dir)
    );
}
