{ gawk, writeScriptBin }:

let
  scriptContent = builtins.replaceStrings [ "/usr/bin/awk" ] [ "${gawk}/bin/gawk" ] (builtins.readFile ./prep-unison-scratch.awk);
in
writeScriptBin "prep-unison-scratch" scriptContent
