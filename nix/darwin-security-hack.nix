{ lib
, stdenv
}:

stdenv.mkDerivation {
  pname = "darwin-security-hack";
  version = "1.0";

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    ${if (stdenv.isDarwin) then "ln -s /usr/bin/security $out/bin/security" else ""}
  '';

  meta = with lib; {
    description = "A hack to add /usr/bin/security to the PATH for darwin builds";
    license = with licenses; [ mit bsd3 ];
    maintainers = [ maintainers.ceedubs ];
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
  };
}
