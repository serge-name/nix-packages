{ unstable, ... }:
let
  inherit (unstable) stdenv writeShellScript kitty glibcLocales mesa_drivers;

  wrapper = writeShellScript "kitty-wrapper" ''
    export LOCALE_ARCHIVE=''${LOCALE_ARCHIVE:-'${glibcLocales}/lib/locale/locale-archive'}
    exec -a "$0" "${kitty}/bin/kitty" "$@"
  '';

  script = writeShellScript "kitty-opengl-driver-path" ''
    echo "${mesa_drivers}"
  '';

in stdenv.mkDerivation {
  inherit (kitty) pname version meta;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    find ${kitty} -mindepth 1 -maxdepth 1 -not -name bin |xargs -n1 ln -st $out
    ln -sT ${wrapper} $out/bin/kitty
    ln -sT ${script} $out/bin/${script.name}
  '';
}
