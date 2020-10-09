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
, fetchurl
, gmp
, less
, ncurses5
, stdenv
, zlib
}:

stdenv.mkDerivation rec {
  pname = "unison-code-manager";
  milestone_id = "M1m";
  version = "1.0.${milestone_id}-alpha";

  src =
    let
      srcUrl = os: "https://github.com/unisonweb/unison/releases/download/release/${milestone_id}/unison-${os}.tar.gz";

      srcArgs = if (stdenv.isDarwin) then
        { os = "osx"; sha256 = "06pxvp753j8pr0pn02l7cswmmas5pk1vlkw83yd04h3f2rx1s61v"; }
      else { os = "linux64"; sha256 = "1qspvfq805d34kz031pf9sqw8kzz7h637kc8lnbjlgvwixxkxc7c"; };

    in
      fetchurl {
        url = srcUrl srcArgs.os;
        inherit (srcArgs) sha256;
      };

  # The tarball is just the prebuilt binary, in the archive root.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = stdenv.lib.optional (!stdenv.isDarwin) autoPatchelfHook;
  buildInputs = stdenv.lib.optionals (!stdenv.isDarwin) [ ncurses5 zlib gmp ];
  propagatedBuildInputs = [ less ];

  installPhase = ''
    mkdir -p $out/bin
    mv ucm $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Modern, statically-typed purely functional language";
    homepage = "https://unisonweb.org/";
    license = with licenses; [ mit bsd3 ];
    maintainers = [ maintainers.ceedubs ];
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
  };
}
