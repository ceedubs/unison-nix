{ cacert, lib, makeWrapper, stdenv, unison-ucm }:

{ pname
, version

  /**
  A Unison transcript file. The transcript should use the ucm `compile` command to compile any desired executables into the working directory.

  # Examples

  ````nix
  src = builtins.toFile "pull-and-compile-http-server.md" ''
    ```ucm
    .> project.create-empty tmp
    tmp/main> pull @unison/httpserver/releases/3.0.2
    tmp/main> compile examples.main unison-hello-server
    ```
    ''
  ````
  */
, src

  /**
  The compiledHash is the hash of the compiled Unison code. This is needed
  because Nix builds restrict network access unless the output hash is known
  ahead of time (which helps with reproducibility and caching). You won't know
  it until you run the derivation for the first time. You can just set this to
  `pkgs.lib.fakeHash` and do a `nix build` or `nix run` and copy the hash
  labeled `got: `.
  */
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
