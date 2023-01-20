{
  description = "My packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    mkPkgs = pkgs: import pkgs { inherit system; config.allowUnfree = true; };
    stable = mkPkgs inputs.nixpkgs;
    unstable = mkPkgs inputs.unstable;
    myLib = import ./lib { inherit (stable) lib; };
  in {
    apps.${system}.repl = import ./lib/repl.nix { inherit stable inputs; };
    packages.${system} = myLib.mkFlakeParts ./packages { inherit stable unstable inputs; };
  };
}
