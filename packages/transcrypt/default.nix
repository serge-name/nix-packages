{ pkgs, ... }:
let
  inherit (import ./_version.nix) version sha256;
in pkgs.transcrypt.overrideAttrs (_: {
  inherit version;

  src = pkgs.fetchFromGitHub {
    owner = "elasticdog";
    repo = "transcrypt";
    rev = "v${version}";
    inherit sha256;
  };

  patches = [ ./helper-scripts_depspathprefix.patch ];
})
