{
  description = "My packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    stable = inputs.nixpkgs.legacyPackages.${system};
    unstable = inputs.unstable.legacyPackages.${system};
    myLib = import ./lib { inherit (stable) lib; };
  in {
    apps.${system}.repl = import ./lib/repl.nix { inherit stable inputs; };
    packages.${system} = myLib.mkFlakeParts ./packages { inherit stable unstable; };
  };
}
