{
  description = "Support for the Unison programming language";

  inputs = {
    nixpkgs-non-darwin.url = "github:nixos/nixpkgs/release-22.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
    unison.url = "github:unisonweb/unison";
    unison.flake = false;
  };

  outputs = { self, nixpkgs-non-darwin, nixpkgs-darwin, flake-utils, unison }:
    let
      systems = flake-utils.lib.defaultSystems;

      overlay = final: prev: {
        darwin-security-hack = final.callPackage ./nix/darwin-security-hack.nix { };

        unison-ucm = final.callPackage ./nix/ucm.nix { };

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
          nixpkgs = if isDarwin system then nixpkgs-darwin else nixpkgs-non-darwin;
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
        }
      ) // { inherit overlay; };
}
