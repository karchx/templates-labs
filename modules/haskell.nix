{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = [
    pkgs.haskellPackages.ghc
    pkgs.haskellPackages.cabal-install
    pkgs.haskellPackages.stack
    pkgs.haskellPackages.hspec
    pkgs.haskellPackages.QuickCheck
  ];
  shellHook = ''
    echo "haskell environment ready!"
    alias n=nvim
  '';
}

