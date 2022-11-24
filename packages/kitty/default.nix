{ stable, ... }:
let
  inherit (stable) lib writeShellScript kitty glibcLocales mesa_drivers;

  script = writeShellScript "kitty-opengl-driver-path" ''
    echo "${mesa_drivers}"
  '';

  patchWrapper = let
    pattern = ''wrapProgram "$out/bin/kitty"'';
  in lib.replaceStrings
    [ pattern ]
    [ ''${pattern} --set-default LOCALE_ARCHIVE "${glibcLocales}/lib/locale/locale-archive"'' ];

in kitty.overrideDerivation(old: {
  installPhase = (patchWrapper old.installPhase) + ''
    ln -s ${script} "$out/bin/${script.name}"
  '';
})
