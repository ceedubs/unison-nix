{
  description = "Support for the Unison programming language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
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

        buildUnisonFromTranscript = final.callPackage ./nix/build-from-transcript.nix { };

        buildUnisonShareProject = final.callPackage ./nix/build-share-project.nix { };

        prep-unison-scratch = final.callPackage ./nix/prep-unison-scratch { };

        vimPlugins = prev.vimPlugins // {
          vim-unison = final.vimUtils.buildVimPlugin {
            name = "vim-unison";
            src = unison;
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
          packages = rec {
            inherit ucm;

            vim-unison = pkgs.vimPlugins.vim-unison;

            inherit (pkgs) prep-unison-scratch buildUnisonFromTranscript buildUnisonShareProject;
          };

          defaultPackage = ucm;
        }
      ) // { inherit overlay; };
}
