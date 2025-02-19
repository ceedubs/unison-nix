# The code in this file is based off of code from the nixpkgs repository:
# https://github.com/NixOS/nixpkgs/blob/df202b418dca671a37ea977716458ab1b718d9c2/pkgs/development/compilers/unison/default.nix
# The original code is licensed under the MIT license (as is this repository) with the following
# notice.
#
# Copyright (c) 2003-2020 Eelco Dolstra and the Nixpkgs/NixOS contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
{
  autoPatchelfHook,
  darwin-security-hack,
  fetchurl,
  fzf,
  git,
  gmp,
  installShellFiles,
  less,
  lib,
  libb2,
  makeWrapper,
  ncurses,
  curl,
  openssl,
  stdenv,
  system,
  zlib,
}: let
  version = "0.5.33";

  # sha256 can be calculated with `nix-prefetch-url <url>`. For example:
  # nix-prefetch-url https://github.com/unisonweb/unison/releases/download/release/0.5.29/ucm-linux-x64.tar.gz
  srcForPlatform = {
    aarch64-darwin = {
      sys = "macos-arm64";
      sha256 = "0g0bxypli0n9dnn8a93nbmnir5flrjhn5gkfnsy7hgrrc5qf3far";
    };
    x86_64-darwin = {
      sys = "macos-x64";
      sha256 = "0jqmbxc1f8s8n2vcrnjlhjj2zl2na1p077z5lf8r26w3w7hrjm9h";
    };
    x86_64-linux = {
      sys = "linux-x64";
      sha256 = "11l0j23a300s52abl64zvvmz1afnd8x8i1kjhjanzzqg0ajsqb3w";
    };
  };

  src = let
    srcArgs = srcForPlatform.${system};
  in
    fetchurl {
      url = "https://github.com/unisonweb/unison/releases/download/release/${version}/ucm-${srcArgs.sys}.tar.gz";
      inherit (srcArgs) sha256;
    };

  ucm = "$out/bin/ucm";
in
  stdenv.mkDerivation rec {
    pname = "unison-code-manager";
    inherit src version;

    # The tarball is just the prebuilt binary, in the archive root.
    sourceRoot = ".";
    dontBuild = true;
    dontConfigure = true;
    doInstallCheck = true;

    nativeBuildInputs = [installShellFiles makeWrapper] ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook;

    buildInputs =
      [git less fzf ncurses zlib]
      ++ (
        if (stdenv.isDarwin)
        then [darwin-security-hack]
        else [gmp]
      );

    binPath = lib.makeBinPath buildInputs;

    installPhase = ''
      mkdir -p $out/{bin,lib}
      mv runtime $out/lib/runtime
      mv unison $out/unison
      mv ui $out/ui

      makeWrapper $out/unison/unison ${ucm} \
        --prefix PATH : ${binPath} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libb2 openssl curl]} \
        --add-flags "--runtime-path $out/lib/runtime/bin/unison-runtime" \
        --set-default UCM_WEB_UI "$out/ui"
    '';

    postInstall = ''
      installShellCompletion --cmd ucm \
        --bash <(${ucm} --bash-completion-script ${ucm}) \
        --fish <(${ucm} --fish-completion-script ${ucm}) \
        --zsh <(${ucm} --zsh-completion-script ${ucm})
    '';

    installCheckPhase = ''
      export XDG_DATA_HOME="$TMP/.local/share"
      echo "ucm version:"
      ${ucm} version | grep -q 'unison version:' || \
        { echo 1>&2 'ERROR: ucm is not the expected version or does not function properly'; exit 1; }
      echo 'ls' | PATH="" ${ucm} --codebase-create $TMP > /dev/null || \
        { echo 1>&2 'ERROR: could not run ls on a fresh ucm codebase'; exit 1; }
    '';

    meta = with lib; {
      description = "Modern, statically-typed purely functional language";
      homepage = "https://unisonweb.org/";
      license = with licenses; [mit bsd3];
      maintainers = [maintainers.ceedubs];
      platforms = attrNames srcForPlatform;
      mainProgram = "ucm";
    };
  }
