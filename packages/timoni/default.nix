{ unstable, inputs, ... }:
let
  inherit (import ./_version.nix) version hash vendorHash;
in
unstable.buildGo121Module rec {
  pname = "timoni";
  inherit version vendorHash;

  src = unstable.fetchFromGitHub {
    owner = "stefanprodan";
    repo = "timoni";
    rev = "v${version}";
    inherit hash;
  };

  subPackages = [ "cmd/timoni" ];
  nativeBuildInputs = [ unstable.installShellFiles ];

  # Some tests require running Kubernetes instance
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X main.VERSION=${version}"
  ];

  postInstall = ''
    installShellCompletion --cmd timoni \
    --bash <($out/bin/timoni completion bash) \
    --fish <($out/bin/timoni completion fish) \
    --zsh <($out/bin/timoni completion zsh)
  '';
}
