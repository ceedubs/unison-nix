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

{ autoPatchelfHook
, darwin-security-hack ? null
, fetchurl
, fzf
, git
, gmp
, installShellFiles
, less
, lib
, makeWrapper
, ncurses
, stdenv
, zlib
}:

let
  ucm = "$out/bin/ucm";
  ui = "$out/bin/ui";
in
stdenv.mkDerivation rec {
  pname = "unison-code-manager";
  milestone_id = "M4e";
  version = "1.0.${milestone_id}-alpha";

  src =
    let
      srcUrl = os: "https://github.com/unisonweb/unison/releases/download/release/${milestone_id}/ucm-${os}.tar.gz";

      # sha256 can be calculated with `nix-prefetch-url <url>`. For example:
      # nix-prefetch-url https://github.com/unisonweb/unison/releases/download/release/M4b/ucm-linux.tar.gz
      srcArgs =
        if (stdenv.isDarwin) then
          { os = "macos"; sha256 = "0rzx5c3wsyanbnhwxjilzgyyjz0l4m90h7nvbpp81rj7qjmhwdxr"; }
        else { os = "linux"; sha256 = "1wccrvp6gxg7pdh1i1anvclkirmpx4b7nwdg8r48j6vc5514v6vm"; };
    in
    fetchurl {
      url = srcUrl srcArgs.os;
      inherit (srcArgs) sha256;
    };

  # The tarball is just the prebuilt binary, in the archive root.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;
  doInstallCheck = true;

  nativeBuildInputs = [ installShellFiles makeWrapper ] ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook;

  darwinBuildInputs = lib.optional (darwin-security-hack != null) darwin-security-hack;
  nonDarwinBuildInputs = [ gmp ];

  buildInputs = [ git less fzf ncurses zlib ] ++ (if (stdenv.isDarwin) then darwinBuildInputs else nonDarwinBuildInputs);

  binPath = lib.makeBinPath buildInputs;

  installPhase = ''
    install -D -m555 -T ucm ${ucm}

    mv ui ${ui}

    wrapProgram ${ucm} \
      --set-default UCM_WEB_UI ${ui} \
      --prefix PATH : ${binPath}
  '';


  postFixup = ''
    installShellCompletion --cmd ucm \
      --bash <(${ucm} --bash-completion-script ${ucm}) \
      --fish <(${ucm} --fish-completion-script ${ucm}) \
      --zsh <(${ucm} --zsh-completion-script ${ucm})
  '';

  installCheckPhase = ''
    export XDG_DATA_HOME="$TMP/.local/share"
    $out/bin/ucm version | grep -q 'ucm version:' || \
      { echo 1>&2 'ERROR: ucm is not the expected version or does not function properly'; exit 1; }
    echo 'ls' | PATH="" $out/bin/ucm --no-base --codebase-create $TMP > /dev/null || \
      { echo 1>&2 'ERROR: could not run ls on a fresh ucm codebase'; exit 1; }
  '';

  meta = with lib; {
    description = "Modern, statically-typed purely functional language";
    homepage = "https://unisonweb.org/";
    license = with licenses; [ mit bsd3 ];
    maintainers = [ maintainers.ceedubs ];
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
    mainProgram = "ucm";
  };
}
