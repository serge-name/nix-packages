{ lib, ... }:
let
  inherit (builtins) listToAttrs;
  inherit (lib) last length remove splitString take;
  inherit (lib.filesystem) listFilesRecursive;
in rec {
  pathParts = x:
    remove "" (splitString "/" x);

  basename = x:
    last (pathParts x);

  pkgName = x:
    let
      parts = pathParts x;
      pLen = length parts;
    in
    last (take (pLen - 1) parts);

  importOrNull = x: args:
    let
      file = basename x;
      pkg = pkgName x;
    in
    if file == "default.nix"
    then { name = pkg; value = import x args; }
    else null;

  mkAttrs = x:
    listToAttrs (remove null x);

  mkPackages = dir: args:
    mkAttrs (map
      (x: importOrNull (toString x) args)
      (listFilesRecursive dir));
}
