{ unstable, ... }:
let
  inherit (import ./_version.nix) version rel sha256;
  inherit (unstable) stdenv fetchurl;

  archs = {
    x86_64-linux = "linux-x86_64";
  };

  arch = archs.${stdenv.system} or (throw "system ${stdenv.system} not supported");

  src = fetchurl {
    url = "https://github.com/crystal-lang/crystal/releases/download/${version}/crystal-${version}-${rel}-${arch}.tar.gz";
    inherit sha256;
  };

in
stdenv.mkDerivation {
  pname = "crystal-binary";

  inherit version src;

  buildCommand = ''
    mkdir -p $out
    tar --strip-components=1 -C $out -xf ${src}
    patchShebangs $out/bin/crystal
  '';
}
