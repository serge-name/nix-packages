{
  description = "My packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    myLib = import ./lib { inherit (nixpkgs) lib; };
  in
    (inputs.flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in rec {
          packages = inputs.flake-utils.lib.flattenTree (myLib.mkPackages ./packages pkgs);
        }
      )
    ) // {
      lib = import ./lib;
    };
}
