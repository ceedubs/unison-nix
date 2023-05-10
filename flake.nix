{
  description = "Support for the Unison programming language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    unison.url = "github:unisonweb/unison";
    unison.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, unison }:
    let
      systems = flake-utils.lib.defaultSystems;

      overlay = final: prev: {
        darwin-security-hack = final.callPackage ./nix/darwin-security-hack.nix { };

        unison-ucm = final.callPackage ./nix/ucm.nix { };

        prep-unison-scratch = final.callPackage ./nix/prep-unison-scratch {};

        vimPlugins = prev.vimPlugins // {
          vim-unison = final.callPackage ./nix/vim-unison.nix {
            inherit (final.vimUtils) buildVimPluginFrom2Nix;
            unisonSrc = unison;
          };
        };

      };
    in
    flake-utils.lib.eachSystem systems
      (
        system:
        let
          isDarwin = sys:
            builtins.match ".*darwin" sys != null;
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

            inherit (pkgs) prep-unison-scratch;
          };

          defaultPackage = ucm;
        }
      ) // { inherit overlay; };
}
