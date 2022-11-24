{ unstable, ... }:
let
  inherit (unstable) lens callPackage;
  google-cloud-sdk = import ../google-cloud-sdk { inherit unstable; };
  appimagePath = unstable.path + "/pkgs/build-support/appimage";

  buildFHSUserEnvBubblewrapAltered = import ./build_fhs_user_env.nix { inherit unstable google-cloud-sdk; };
in lens.override({
  appimageTools = callPackage appimagePath {
    buildFHSUserEnv = buildFHSUserEnvBubblewrapAltered;
  };
})
