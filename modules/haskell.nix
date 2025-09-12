{ pkgs, ... }:

{
  devShells.haskell = pkgs.mkShell {
    buildInputs = [
      pkgs.ghc
      pkgs.cabal-install
      pkgs.stack
      pkgs.hspec
      pkgs.QuickCheck
    ];
    shellHook = ''
      echo "haskell environment ready!"
      alias n=nvim
    '';
  };
}

