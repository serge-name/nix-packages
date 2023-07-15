{ unstable, ... }:
let
  inherit (unstable) stdenv writeShellScript kitty glibcLocales mesa_drivers gnugrep;

  grep = gnugrep + "/bin/grep";
  mesa_lib = mesa_drivers + "/lib";
  mesa_dri = mesa_lib + "/dri";

  foo = varname: path: ''
    if ! ${grep} -qF "${path}" <<< "''${${varname}:-}"; then
      export ${varname}="${path}''${${varname}:+:}''${${varname}:-}"
    fi
  '';

  wrapper = writeShellScript "kitty-wrapper" ''
    export LOCALE_ARCHIVE=''${LOCALE_ARCHIVE:-'${glibcLocales}/lib/locale/locale-archive'}
    ${foo "LD_LIBRARY_PATH" mesa_lib}
    ${foo "LIBGL_DRIVERS_PATH" mesa_dri}
    exec -a "$0" "${kitty}/bin/kitty" "$@"
  '';

in stdenv.mkDerivation {
  inherit (kitty) pname version meta;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    find ${kitty} -mindepth 1 -maxdepth 1 -not -name bin |xargs -n1 ln -st $out
    ln -sT ${wrapper} $out/bin/kitty
  '';
}
