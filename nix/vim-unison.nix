{ buildVimPluginFrom2Nix, unisonSrc }:

buildVimPluginFrom2Nix {
  name = "vim-unison";
  src = unisonSrc + "/editor-support/vim";
}
