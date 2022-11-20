{ stable, ... }:
let
  inherit (import ./_version.nix) version sha256;
in stable.transcrypt.overrideAttrs (_: {
  inherit version;

  src = stable.fetchFromGitHub {
    owner = "elasticdog";
    repo = "transcrypt";
    rev = "v${version}";
    inherit sha256;
  };

  patches = [ ./helper-scripts_depspathprefix.patch ];
})
