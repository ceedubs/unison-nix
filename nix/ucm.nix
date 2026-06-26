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
  zlib,
}: let
  ## NB: When changing this, also change `inputs.unison.url` in flake.nix.
  version = "1.3.0";

  # hash can be calculated with `nix store prefetch-file <url>`. For example:
  # nix store prefetch-file https://github.com/unisonweb/unison/releases/download/release/1.0.0/ucm-linux-x64.tar.gz
  srcForPlatform = {
    aarch64-darwin = {
      sys = "macos-arm64";
      hash = "sha256-DBNZx90rLqeRrjAnscamI8sduIH966az+AfMpWzberk=";
    };
    x86_64-darwin = {
      sys = "macos-x64";
      hash = "sha256-ei/w82erwVf3oLbXcisBkPv2/k4gvwSxshTg7PWijhw=";
    };
    x86_64-linux = {
      sys = "linux-x64";
      hash = "sha256-DFLiI3Rro2ApmT84xndGdaLWH/Ad/HXEY6bj331tQzs=";
    };
    aarch64-linux = {
      sys = "linux-arm64";
      hash = "sha256-6XRr8IOwRhZlGFD9xb29cvqqYVjZFzSvh3S52Cq4HMo=";
    };
  };

  src = let
    srcArgs = srcForPlatform.${stdenv.hostPlatform.system};
  in
    fetchurl {
      url = "https://github.com/unisonweb/unison/releases/download/release/${version}/ucm-${srcArgs.sys}.tar.gz";
      inherit (srcArgs) hash;
    };

  unison = "$out/unison/unison";
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
      runHook preInstall

      mkdir -p $out/{bin,lib}
      mv unison $out/unison
      mv ui $out/ui

      makeWrapper ${unison} ${ucm} \
        --prefix PATH : ${binPath} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libb2 openssl curl]} \
        --set-default UCM_WEB_UI "$out/ui"

      runHook postInstall
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
