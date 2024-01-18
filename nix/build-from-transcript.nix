{ cacert, lib, makeWrapper, stdenv, unison-ucm }:

{ pname
, version
, src
, compiledHash
, meta ? { }
}:

let
  compiled = stdenv.mkDerivation {
    # include the ucm version and transcript hash in the derivation name so it is rebuilt if either changes
    pname = pname + "_ucm-${unison-ucm.version}_${builtins.hashFile "sha256" src}";
    inherit version;

    nativeBuildInputs = [ cacert ];
    buildCommand = ''
      export XDG_DATA_HOME="$TMP/.local/share"
      ${unison-ucm}/bin/ucm -C . transcript ${src}
      mkdir -p $out/share
      mv *.uc $out/share/
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = compiledHash;
  };

in
stdenv.mkDerivation {
  inherit pname version meta;
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ ];
  buildCommand = ''
    mkdir -p $out/bin

    for ucFile in ${compiled}/share/*.uc; do
      makeWrapper "${unison-ucm}/bin/ucm" "$out/bin/$(basename "$ucFile" .uc)" \
        --add-flags "run.compiled $ucFile"
    done
  '';
}
