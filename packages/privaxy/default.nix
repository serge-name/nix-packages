{ unstable, inputs, ... }:
let
  inherit (import ./_version.nix) version sha256;

  src = unstable.fetchFromGitHub {
    owner = "serge-name";
    repo = "privaxy";
    rev = "v${version}-nix";
    inherit sha256;
  };

  pkgs = import inputs.cargo2nix.inputs.nixpkgs {
    inherit (unstable) system;
    overlays = [ inputs.cargo2nix.overlays.default ];
  };

  rustPkgs = pkgs.rustBuilder.makePackageSet {
    rustVersion = "1.61.0";
    packageFun = import "${src}/Cargo.nix";
  };
in (rustPkgs.workspace.privaxy {}).bin
