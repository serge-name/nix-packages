{
  description = "My packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    myLib = import ./lib { inherit (nixpkgs) lib; };
  in {
    packages.${system} = myLib.mkPackages ./packages pkgs;
  };
}
