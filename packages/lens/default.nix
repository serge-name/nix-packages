{ unstable, ... }:
let
  inherit (import ./_version.nix) build hash;
  inherit (unstable) fetchurl appimageTools nss_latest makeWrapper lib glibcLocales mesa_drivers;

  pname = "lens-desktop";
  src = fetchurl {
    sha256 = hash;
    url = "https://downloads.k8slens.dev/ide/Lens-${build}-latest.x86_64.AppImage";
  };

  name = "${pname}-${build}";

  configDir = "$HOME/.config/Lens";

  google-cloud-sdk = import ../google-cloud-sdk { inherit unstable; };

  appimageContents = appimageTools.extract {
    inherit name src;
    postExtract =
      ''
        find $out/resources/app.asar.unpacked/node_modules/@lensapp/lenscloud-lens-extension -type f -name "*.js" -print0 \
          | xargs -0 truncate -s0

        source "${makeWrapper}/nix-support/setup-hook"
        wrapProgram "$out/resources/x64/lens-k8s-proxy" \
          --run 'source "${configDir}/environment_k8s_proxy" || true'
      '';
  };

  mkRoBindTrySame = map (x: "--ro-bind-try ${x} ${x}");
  mkBindSame = map (x: "--bind ${x} ${x}");
in
appimageTools.wrapAppImage {
  inherit name;

  src = appimageContents;

  extraBwrapArgs = [
    "--tmpfs /home"
    "--ro-bind $HOME/.Xauthority $HOME/.Xauthority"
  ] ++ mkRoBindTrySame [
    "$HOME/.config/fontconfig"
    "$HOME/.config/gtk-2.0"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/user-dirs.dirs"
    "$HOME/.local/share/fonts"
    "/var/cache/fontconfig"
  ] ++ mkBindSame [
    # FIXME: create dirs if absent
    configDir
    "$HOME/.k8slens"
    "$HOME/.cache/mesa_shader_cache"
    "$HOME/.cache/fontconfig"
    "$HOME/.config/gcloud"
    "$HOME/.kube"
    "$HOME/Downloads"
  ];

  extraInstallCommands =
    ''
      mv $out/bin/${name} $out/bin/${pname}
      source "${makeWrapper}/nix-support/setup-hook"
      wrapProgram $out/bin/${pname} \
        --run 'export SHELL="$BASH"' \
        --run 'source "${configDir}/environment_k8s_proxy"' \
        --run 'chmod -R u+w "${configDir}/extensions" >& /dev/null' \
        --set-default LOCALE_ARCHIVE "${glibcLocales}/lib/locale/locale-archive" \
        --suffix LD_LIBRARY_PATH : "${mesa_drivers}/lib" \
        --suffix LIBGL_DRIVERS_PATH : "${mesa_drivers}/lib/dri" \
        --prefix PATH : "${google-cloud-sdk}/bin" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    '';

  extraPkgs = _: [ nss_latest ];
}
