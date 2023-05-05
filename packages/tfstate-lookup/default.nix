{ unstable, ... }:
let
  inherit (import ./_version.nix) version sha256 vendorHash;
  inherit (unstable) lib buildGoModule fetchFromGitHub;
  pname = "tfstate-lookup";

  src = fetchFromGitHub {
    owner = "fujiwara";
    repo = pname;
    rev = "v${version}";
    inherit sha256;
  };

in buildGoModule {
  inherit pname version vendorHash src;

  doCheck = false;

  meta = {
    description = "Lookup resource attributes in tfstate.";
    longDescription = ''
      Lookup resource attributes in tfstate.
    '';
    inherit (src.meta) homepage;
    license = lib.licenses.mpl20;
    platforms = lib.platforms.unix;
  };
}
