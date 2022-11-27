# Also see https://github.com/NixOS/nix/issues/3803

{ stable, inputs, ... }:
let
  inherit (inputs.flake-utils.lib) mkApp;
  inherit (stable) writeShellScriptBin;
in
mkApp {
  drv = writeShellScriptBin "repl" ''
    confnix=$(mktemp -t nix-repl-flake-is-fl-var.XXXXXXXXXXXX)
    flake_dir="$(git rev-parse --show-toplevel || pwd)"
    cmd="{ fl = builtins.getFlake (toString $flake_dir); }"
    echo $cmd >$confnix
    trap "rm -f $confnix" EXIT
    nix repl $confnix
  '';
}
