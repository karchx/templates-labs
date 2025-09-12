{ pkgs, ... }:

{
  devShells.cpp = pkgs.mkShell {
    buildInputs = [
      pkgs.gcc
      pkgs.clang
      pkgs.cmake
      pkgs.ninja
      pkgs.gdb
    ];
    shellHook = ''
      echo "C++ environment ready!"
    '';
  };
}

