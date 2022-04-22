{
  description = "Support for the Unison programming language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    unison.url = "github:unisonweb/unison";
    unison.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, unison }:
    let
      systems = flake-utils.lib.defaultSystems;

      overlay = final: prev: {
        unison-ucm = final.callPackage ./nix/ucm.nix {};

        vimPlugins = prev.vimPlugins // {
          vim-unison = final.callPackage ./nix/vim-unison.nix {
            inherit (final.vimUtils) buildVimPluginFrom2Nix;
            unisonSrc = unison;
          };
        };

        unison-stack = final.callPackage ./nix/unison-stack.nix {
          unisonSrc = unison;
        };
      };
    in
      flake-utils.lib.eachSystem systems (
        system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ overlay ];
            };
            ucm = pkgs.unison-ucm;
          in
            {
              packages = {
                inherit ucm;

                vim-unison = pkgs.vimPlugins.vim-unison;
              };

              defaultPackage = ucm;

              devShell = pkgs.unison-stack;
            }
      ) // { inherit overlay; };
}
