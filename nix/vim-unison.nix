{ buildVimPluginFrom2Nix, curl, jq, unisonSrc }:

buildVimPluginFrom2Nix {
  name = "vim-unison";
  src = unisonSrc + "/editor-support/vim";

  patchPhase = ''
    substituteInPlace autoload/unison.vim \
      --replace '"curl"' '"${curl}/bin/curl"' \
      --replace '"jq"' '"${jq}/bin/jq"'
  '';
}
