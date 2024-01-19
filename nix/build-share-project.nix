{ buildUnisonFromTranscript, lib }:

/**
Compile functions from a project hosted on Unison Share into executables.
*/
{ pname
, version

  /**
  The Unison Share user handle of owner of the project to compile.
  For example in the project `@unison/base` the user handle is `unison`.
  */
, userHandle

  /**
  The name of the project to compile.
  For example in the project `@unison/base` the project name is `base`.
  */
, projectName

  /** A release version of the project to compile (ex: `3.1.2`). */
, projectReleaseVersion ? args.version

  /**
  The compiledHash is the hash of the compiled Unison code. This is needed
  because Nix builds restrict network access unless the output hash is known
  ahead of time (which helps with reproducibility and caching). You won't know
  it until you run the derivation for the first time. You can just set this to
  `pkgs.lib.fakeHash` and do a `nix build` or `nix run` and copy the hash
  labeled `got: `.
  */
, compiledHash

  /**
  A list of executables to compile. Each key is an executable name and each
  value is a fully-qualified entry function name. For example, `snake =
  examples.snake.main` will generate a `/bin/snake` executable out of the
  function `examples.snake.main : '{IO, Exception} ()`.
  */
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
