{ fzf, glibcLocales, git, gmp, less, lib, libiconv, mkShell, ncurses, ormolu, stack, stdenv, darwin, zlib }:

let
  nativeLibs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Cocoa CoreServices libiconv ]);

in
mkShell {
  description = "Support for developing the compiler/tooling for the Unison programming language";

  buildInputs = [
    git
    less
    ncurses
    zlib
    fzf
    glibcLocales
    gmp
    ormolu
    stack
  ] ++ nativeLibs;
}
