{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs {} }:

{
  unison-ucm = pkgs.callPackage ./ucm.nix {};

  vim-unison = pkgs.callPackage ./vim-unison.nix {
    inherit (pkgs.vimUtils) buildVimPluginFrom2Nix;
    unisonSrc = sources.unison;
  };

  unison-stack = pkgs.callPackage ./unison-stack.nix {
    unisonSrc = sources.unison;
  };
}
