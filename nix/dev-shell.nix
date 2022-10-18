{ darwin, fzf, glibcLocales, git, gmp, less, lib, libiconv, makeWrapper, mkShell, ncurses, ormolu, stack, stdenv, symlinkJoin, system, zlib }:

let
  isX86Darwin = system == "x86_64-darwin";
  nativeLibs = lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Cocoa CoreServices libiconv ]);

  # Admittedly I'm flailing a bit here. --nix seems to work well on other
  # platforms, but when I try it with x86 darwin, it generates assembly that is
  # invalid for the platform. It seems like some sort of clang or llvm mismatch
  # or something, but I can't figure it out.
  stack-wrapped = if isX86Darwin then stack else
  symlinkJoin {
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
