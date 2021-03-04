{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { config.allowBroken = true; } }:

{
  unison-ucm = pkgs.callPackage ./ucm.nix {};

  unison = pkgs.callPackage ./unison-cabal.nix {
    inherit sources;
  };

  vim-unison = pkgs.callPackage ./vim-unison.nix {
    inherit (pkgs.vimUtils) buildVimPluginFrom2Nix;
    unisonSrc = sources.unison;
  };

  unison-stack = pkgs.callPackage ./unison-stack.nix {
    unisonSrc = sources.unison;
  };
}
