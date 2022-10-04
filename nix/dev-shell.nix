{ darwin, fzf, glibcLocales, git, gmp, less, lib, makeWrapper, mkShell, ncurses, ormolu, stack, stdenv, symlinkJoin, zlib }:

let
  nativeLibs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Cocoa CoreServices ]);
  stack-wrapped = symlinkJoin {
    name = "stack";
    buildInputs = [ makeWrapper ];
    paths = [ stack ];
    postBuild = ''
      wrapProgram "$out/bin/stack" \
        --add-flags "--nix"
    '';
  };

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
    stack-wrapped
  ] ++ nativeLibs;
}
