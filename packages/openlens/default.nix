{ unstable, ... }:
let
  inherit (unstable) appimageTools writeShellScript kubernetes-helm kubectl bash coreutils glibcLocales mesa_drivers gnugrep;
  inherit (unstable.lib) getName;
  inherit (unstable.openlens) name src meta;

  pname = getName name;
  configDir = "$HOME/.config/OpenLens";

  resources = (appimageTools.extractType2 {
    inherit name src;
  }).outPath + "/resources/x64";

  google-cloud-sdk = import ../google-cloud-sdk { inherit unstable; };

  resourceWrappers = [
    (writeShellScript "helm" ''
      exec ${kubernetes-helm}/bin/helm "$@"
    '')
    (writeShellScript "kubectl" ''
      exec ${kubectl}/bin/kubectl "$@"
    '')
    (writeShellScript "lens-k8s-proxy" ''
      export PATH=${coreutils}/bin:${google-cloud-sdk}/bin:$PATH
      source ${configDir}/environment_k8s_proxy || true
      exec ''${0}-orig "$@"
    '')
  ];

  mkRoBindTrySame = map (x: "--ro-bind-try ${x} ${x}");
  mkBindSame = map (x: "--bind ${x} ${x}");

  mkRoBind = from: to: "--ro-bind ${from} ${to}";
  mkBindWrappers = map (x: mkRoBind x.outPath "${resources}/${x.name}");

  grep = gnugrep + "/bin/grep";
  mesa_lib = mesa_drivers + "/lib";
  mesa_dri = mesa_lib + "/dri";

  appendEnvColon = varname: path: ''
    if ! ${grep} -qF "${path}" <<< "''${${varname}:-}"; then
      export ${varname}="${path}''${${varname}:+:}''${${varname}:-}"
    fi
  '';

in appimageTools.wrapType2 {
  inherit name src meta;

  extraBwrapArgs = [
    ''--tmpfs ${resources}''
  ] ++ mkBindWrappers resourceWrappers ++ [
    (mkRoBind "${resources}/lens-k8s-proxy" "${resources}/lens-k8s-proxy-orig")

    ''--tmpfs /home''
    ''--ro-bind $HOME/.Xauthority $HOME/.Xauthority''
  ] ++ mkRoBindTrySame [
    ''$HOME/.config/fontconfig''
    ''$HOME/.config/gtk-2.0''
    ''$HOME/.config/gtk-3.0''
    ''$HOME/.config/user-dirs.dirs''
    ''$HOME/.local/share/fonts''
    ''/var/cache/fontconfig''
  ] ++ mkBindSame [
    # FIXME: create dirs if absent
    configDir
    ''$HOME/.k8slens''
    ''$HOME/.cache/mesa_shader_cache''
    ''$HOME/.cache/fontconfig''
    ''$HOME/.config/gcloud''
    ''$HOME/.kube''
    ''$HOME/Downloads''
  ];

  extraInstallCommands = ''
    mv $out/bin/${name} $out/bin/.${name}
    configDir='${configDir}'

    cat >$out/bin/${pname} <<__
    #!${bash}/bin/bash
    export LOCALE_ARCHIVE="${glibcLocales}/lib/locale/locale-archive"
    ${appendEnvColon "LD_LIBRARY_PATH" mesa_lib}
    ${appendEnvColon "LIBGL_DRIVERS_PATH" mesa_dri}
    export SHELL="${bash}/bin/bash"
    source "$configDir/environment_k8s_proxy"
    chmod -R u+w "$configDir/extensions" >& /dev/null
    exec $out/bin/.${name} "\$@"
    __

    chmod +x $out/bin/${pname}
  '';
}
