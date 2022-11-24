{ unstable, ... }:
let
  sdk = unstable.google-cloud-sdk;
in sdk.withExtraComponents ([
  sdk.components.gke-gcloud-auth-plugin
])
