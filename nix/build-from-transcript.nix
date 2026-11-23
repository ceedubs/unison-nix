{
  cacert,
  lib,
  makeWrapper,
  stdenv,
  ucm,
}: {
  pname,
  version,
  /*
  An optional folder with additional sources you may like to use when
  evaluating your transcript file.
  */
  src ? "",
  /*
  A Unison transcript file. The transcript should use the ucm `compile` command to compile any desired executables into the working directory.

  # Examples

  ````nix
  transcript = builtins.toFile "pull-and-compile-http-server.md" ''
    ```ucm
    scratch/main> pull @unison/httpserver/releases/3.0.2
    scratch/main> compile examples.main unison-hello-server
    ```
    ''
  ````
  */
  transcript,
  /*
  The compiledHash is the hash of the compiled Unison code. This is needed
  because Nix builds restrict network access unless the output hash is known
  ahead of time (which helps with reproducibility and caching). You won't know
  it until you run the derivation for the first time. You can just set this to
  `pkgs.lib.fakeHash` and do a `nix build` or `nix run` and copy the hash
  labeled `got: `.
  */
  compiledHash,
  /*
  Build standalone executables with `unisonrt bundle` instead of wrapping `ucm run.compiled`
  */
  bundle ? false,
  /*
  Wrap `unisonrt` instead of `ucm run.compiled`. It starts faster since it has no parser, typechecker or codebase.
  */
  useUnisonrt ? false,
  meta ? {},
}:
assert lib.assertMsg (!(bundle && useUnisonrt)) "buildFromTranscript: `bundle` and `useUnisonrt` are mutually exclusive"; let
  compiled = stdenv.mkDerivation {
    # include the ucm version and transcript hash in the derivation name so it is rebuilt if either changes
    pname = pname + "_ucm-${ucm.version}_${builtins.hashFile "sha256" transcript}";
    inherit version;

    nativeBuildInputs = [cacert];
    buildCommand = ''
      export XDG_DATA_HOME="$TMP/.local/share"
      [ ! -z "${src}" ] && cp -r ${src}/. .
      ${ucm}/bin/ucm -C . transcript ${transcript}
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
    nativeBuildInputs = [makeWrapper];
    buildInputs = [];
    buildCommand =
      if bundle
      then ''
        mkdir -p $out/bin $out/libexec

        for ucFile in ${compiled}/share/*.uc; do
          name="$(basename "$ucFile" .uc)"
          ${ucm}/bin/unisonrt bundle "$ucFile" -o "$out/libexec/$name"
          makeWrapper "$out/libexec/$name" "$out/bin/$name" \
            ${lib.escapeShellArgs ucm.runtimeWrapperArgs}
        done
      ''
      else if useUnisonrt
      then ''
        mkdir -p $out/bin

        for ucFile in ${compiled}/share/*.uc; do
          makeWrapper "${ucm}/bin/unisonrt" "$out/bin/$(basename "$ucFile" .uc)" \
            --add-flags "$ucFile"
        done
      ''
      else ''
        mkdir -p $out/bin

        for ucFile in ${compiled}/share/*.uc; do
          makeWrapper "${ucm}/bin/ucm" "$out/bin/$(basename "$ucFile" .uc)" \
            --add-flags "run.compiled $ucFile"
        done
      '';
  }
