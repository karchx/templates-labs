{
  description = "Templates labs with flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
        devShells = forAllSystems (pkgs: {
            cpp = import ./modules/cpp.nix { inherit pkgs; };
            haskell = import ./modules/haskell.nix { inherit pkgs; };
        });
    };

    templates = {
        cpp = {
            path = ./modules/cpp;
            description = "Environment to c++";
        };
    };
}
