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

{ fetchurl
, gmp
, installShellFiles
, less
, lib
, ncurses5
, stdenv
, zlib
}:

let
  dynamic-linker = stdenv.cc.bintools.dynamicLinker;

  patchelf = libPath :
    if stdenv.isDarwin
      then ""
      else
        ''
          chmod u+w $UCM
          patchelf --interpreter ${dynamic-linker} --set-rpath ${libPath} $UCM
          chmod u-w $UCM
        '';
in
stdenv.mkDerivation rec {
  pname = "unison-code-manager";
  milestone_id = "M2j";
  version = "1.0.${milestone_id}-alpha";

  src =
    let
      srcUrl = os: "https://github.com/unisonweb/unison/releases/download/release/${milestone_id}/ucm-${os}.tar.gz";

      # sha256 can be calculated with `nix-prefetch-url <url>`. For example:
      # nix-prefetch-url https://github.com/unisonweb/unison/releases/download/release/M2j/ucm-linux.tar.gz
      srcArgs = if (stdenv.isDarwin) then
        { os = "macos"; sha256 = "0lrj37mfqzwg9n757ymjb440jx51kj1s8g6qv9vis9pxckmy0m08"; }
      else { os = "linux"; sha256 = "0qvin1rlkjwijchsijq3vbnn4injawchh2w97kyq7i3idh8ccl59"; };
    in
      fetchurl {
        url = srcUrl srcArgs.os;
        inherit (srcArgs) sha256;
      };

  # The tarball is just the prebuilt binary, in the archive root.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;

  # Without this the dynamic linker complains "ucm: ucm: no version information available (required by ucm)"
  dontStrip = true;

  buildInputs = lib.optionals (!stdenv.isDarwin) [ ncurses5 zlib gmp ];
  propagatedBuildInputs = [ less ];

  libPath = lib.makeLibraryPath (buildInputs ++ propagatedBuildInputs);

  installPhase = ''
    UCM="$out/bin/ucm"

    install -D -m555 -T ucm $UCM
    ${patchelf libPath}

    mkdir -p $out/share/bash-completion/completions
    $UCM --bash-completion-script $UCM > $out/share/bash-completion/completions/ucm.bash
    mkdir -p $out/share/fish/vendor_completions.d/
    $UCM --fish-completion-script $UCM > $out/share/fish/vendor_completions.d/ucm.fish
    mkdir -p $out/share/zsh/site-functions/
    $UCM --zsh-completion-script $UCM > $out/share/zsh/site-functions/_ucm
  '';

  postInstall = ''
    installShellCompletion --bash $out/share/bash-completion/completions/ucm.bash
    installShellCompletion --fish $out/share/fish/vendor_completions.d/ucm.fish
    installShellCompletion --zsh $out/share/zsh/site-functions/_ucm
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
