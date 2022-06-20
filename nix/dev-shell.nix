{ autoPatchelfHook, fzf, glibcLocales, git, gmp, less, mkShell, ncurses, ormolu, stack, stdenv, darwin, zlib }:

mkShell {
  description = "Support for developing the compiler/tooling for the Unison programming language";

  native_libs =
    if (stdenv.isDarwin) then (with darwin.apple_sdk.frameworks; [ Cocoa CoreServices ])
    else [ autoPatchelfHook ];

  buildInputs = [
    git
    less
    ncurses
    zlib
    zlib.dev
    zlib.out
    fzf
    glibcLocales
    gmp
    ormolu
    stack
  ];
}
