{
  description = "My packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    stable = inputs.nixpkgs.legacyPackages.${system};
    unstable = inputs.unstable.legacyPackages.${system};
    myLib = import ./lib { inherit (stable) lib; };
  in {
    packages.${system} = myLib.mkFlakeParts ./packages { inherit stable unstable; };
  };
}
