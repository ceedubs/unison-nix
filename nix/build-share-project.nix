{ buildUnisonFromTranscript, lib }:

{ pname
, version
, userHandle
, projectName
, projectReleaseVersion ? args.version
, compiledHash
, executables ? { pname = "main"; }
, meta ? { }
}@args :

let
  compileCommands = lib.attrsets.mapAttrsToList
    (executableName: functionName: "tmp/main> compile ${functionName} ${executableName}")
    executables;

  transcript = ''
    ```ucm
    .> project.create-empty tmp
    tmp/main> pull @${userHandle}/${projectName}/releases/${projectReleaseVersion}
    ${lib.strings.concatStringsSep "\n" compileCommands}
    ```
  '';

in
buildUnisonFromTranscript {
  inherit pname version compiledHash meta;

  src = builtins.toFile "${pname}-compile-transcript-${version}.md" transcript;
}
