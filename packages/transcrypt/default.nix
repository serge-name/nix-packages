{ stable, ... }:
let
  inherit (import ./_version.nix) version sha256;
  inherit (stable) fetchFromGitHub transcrypt;
in transcrypt.overrideAttrs (_: {
  inherit version;

  src = fetchFromGitHub {
    owner = "elasticdog";
    repo = "transcrypt";
    rev = "v${version}";
    inherit sha256;
  };

  patches = [ ./helper-scripts_depspathprefix.patch ];
})
