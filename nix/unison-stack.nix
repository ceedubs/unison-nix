{ autoPatchelfHook, darwin, ghc, git, gmp, haskell, less, lib, ormolu, stdenv, unisonSrc ? null, zlib }:

let
  libs = [ git less zlib gmp ormolu ];

  native_libs =
    if (stdenv.isDarwin) then (with darwin.apple_sdk.frameworks; [Cocoa CoreServices])
    else [autoPatchelfHook];

in haskell.lib.buildStackProject {
  inherit ghc;
  nativeBuildInputs = native_libs;
  buildInputs = libs;
  name = "unison-stack";
  src = unisonSrc;
}
