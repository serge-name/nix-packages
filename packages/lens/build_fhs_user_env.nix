{ unstable, google-cloud-sdk, ... }:
let
  inherit (unstable) buildFHSUserEnvBubblewrap writeShellScript
                     bash coreutils kubernetes-helm kubectl;
in x:
  let
    # FIXME: ugly
    lensExtracted = __head(__match "^.* (/nix/store/[^ ]+).*$" x.runScript);

    mkRoBind = src: targetExe:
      ''--ro-bind ${src} ${lensExtracted}/resources/x64/${targetExe}'';

    wrapperLens = writeShellScript "${x.name}-wrapper-lens" ''
      p="$HOME/.config/Lens/extensions"
      if [ -d "$p" ]; then
        chmod -R u+w "$p"
      fi

      exec $(dirname $(${coreutils}/bin/readlink -m $0))/.lens "$@"
    '';

    wrapperHelm = writeShellScript "${x.name}-wrapper-helm" ''
      exec ${kubernetes-helm}/bin/helm "$@"
    '';
    wrapperKubectl = writeShellScript "${x.name}-wrapper-kubectl" ''
      exec ${kubectl}/bin/kubectl "$@"
    '';
    wrapperLensK8sProxy = writeShellScript "${x.name}-wrapper-lens-k8s-proxy" ''
      export PATH=${coreutils}/bin:${google-cloud-sdk}/bin:$PATH

      source $HOME/.config/Lens/environment_k8s_proxy || true

      exec ${lensExtracted}/resources/x64/lens-k8s-proxy-orig "$@"
    '';
  in buildFHSUserEnvBubblewrap(x // rec {
    extraBwrapArgs = (x.extraBwrapArgs or []) ++ [
      ''--tmpfs ${lensExtracted}/resources/x64''
      (mkRoBind wrapperHelm "helm")
      (mkRoBind wrapperKubectl "kubectl")
      (mkRoBind wrapperLensK8sProxy "lens-k8s-proxy")
      (mkRoBind "${lensExtracted}/resources/x64/lens-k8s-proxy" "lens-k8s-proxy-orig")

      ''--tmpfs /home''

      ''--ro-bind $HOME/.Xauthority $HOME/.Xauthority''
      ''--ro-bind-try $HOME/.config/fontconfig $HOME/.config/fontconfig''
      ''--ro-bind-try $HOME/.config/gtk-2.0 $HOME/.config/gtk-2.0''
      ''--ro-bind-try $HOME/.config/gtk-3.0 $HOME/.config/gtk-3.0''
      ''--ro-bind-try $HOME/.config/user-dirs.dirs $HOME/.config/user-dirs.dirs''
      ''--ro-bind-try $HOME/.local/share/fonts $HOME/.local/share/fonts''

      ''--bind $HOME/.config/Lens $HOME/.config/Lens''
      ''--bind $HOME/.k8slens $HOME/.k8slens''
      ''--bind $HOME/.config/gcloud $HOME/.config/gcloud''
      ''--bind $HOME/.kube $HOME/.kube''
      ''--bind $HOME/Downloads $HOME/Downloads''
    ];

    extraInstallCommands = x.extraInstallCommands + ''
      lens=$(${coreutils}/bin/readlink -m $out/bin/lens)
      rm $out/bin/lens
      cat >$out/bin/lens <<__
      #!${bash}/bin/bash
      chmod -R u+w "\$HOME/.config/Lens/extensions" || true
      exec $lens "\$@"
      __
      chmod +x $out/bin/lens
    '';

    # runScript = "${coreutils}/bin/ls -la $HOME";  # FIXME: debug
  })
