# Support for working on the Unison language/tooling through a dev environment
# that includes Stack.
#
# Some of this is taken from or inspired by https://docs.haskellstack.org/en/stable/nix_integration/

{ darwin, fzf, glibcLocales, ghc, git, gmp, less, lib, libiconv, makeWrapper, mkShell, ncurses, ormolu, stack, stdenv, symlinkJoin, system, zlib }:

let
  nativeLibs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Cocoa ]);

  devTools = [
    ghc
    git
    less
    ncurses
    zlib
    fzf
    glibcLocales
    gmp
    ormolu
    stack-wrapped
  ] ++ nativeLibs;

  stack-wrapped = symlinkJoin {
    name = "stack";
    buildInputs = [ makeWrapper ];
    paths = [ stack ];
    postBuild = ''
      wrapProgram "$out/bin/stack" \
        --add-flags "\
          --no-nix \
          --system-ghc \
          --no-install-ghc \
        "
    '';
  };

in
mkShell {
  description = "Support for developing the compiler/tooling for the Unison programming language";

  buildInputs = devTools;

  # Make external Nix c libraries like zlib known to GHC
  LD_LIBRARY_PATH = lib.makeLibraryPath devTools;
}
