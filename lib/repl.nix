# Also see https://github.com/NixOS/nix/issues/3803

{ stable, inputs, ... }:
let
  inherit (inputs.flake-utils.lib) mkApp;
  inherit (stable) writeShellScriptBin git;
in
mkApp {
  drv = writeShellScriptBin "repl" ''
    set -euC -o pipefail
    flake_dir=$("${git}/bin/git" rev-parse --show-toplevel || pwd)
    cmd='{ fl = builtins.getFlake (builtins.toString "'"$flake_dir"'"); }'
    exec nix repl --expr "$cmd"
  '';
}
