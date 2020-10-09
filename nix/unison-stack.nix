{ autoPatchelfHook, darwin, ghc, git, gmp, haskell, less, lib, ncurses5, stdenv, unisonSrc ? null, zlib }:

let
  libs = [ git less ncurses5 zlib gmp ];

  native_libs =
    if (stdenv.isDarwin) then (with darwin.apple_sdk.frameworks; [Cocoa CoreServices])
    else [autoPatchelfHook];

in haskell.lib.buildStackProject {
  inherit ghc;
  nativeBuildInputs = native_libs;
  buildInputs = libs;
  name = "unison-stack";
  src = if lib.inNixShell then null else unisonSrc;
}
