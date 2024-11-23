{
  description = "Support for the Unison programming language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-24.05";
    };
    unison = {
      flake = false;
      url = "github:unisonweb/unison";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
    unison,
  }: let
    systems = flake-utils.lib.defaultSystems;

    tree-sitter-unison-github = {
      owner = "kylegoetz";
      repo = "tree-sitter-unison";
      rev = "1.1.4";
      sha256 = "89vFguMlPfKzQ4nmMNdTNFcEiCYH0eSws87Llm88e+I=";
    };

    localPackages = pkgs: let
      darwin-security-hack = pkgs.callPackage ./nix/darwin-security-hack.nix {};
    in {
      ucm = pkgs.callPackage ./nix/ucm.nix {inherit darwin-security-hack;};

      vim-unison = pkgs.vimUtils.buildVimPlugin {
        name = "vim-unison";
        src = unison + "/editor-support/vim";
      };
    };
  in
    flake-utils.lib.eachSystem systems
    (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages =
          {default = self.packages.${system}.ucm;} // localPackages pkgs;

        ## Deprecated
        defaultPackage = self.packages.${system}.default;

        formatter = pkgs.alejandra;
      }
    )
    // {
      overlays = {
        default = final: prev: let
          localPkgs = localPackages final;
        in {
          emacsPackagesFor = emacs:
            (prev.emacsPackagesFor emacs).overrideScope'
            (self.overlays.emacs final prev);

          tree-sitter = prev.tree-sitter.override {
            extraGrammars = self.lib.tree-sitter-grammars final;
          };

          ## Renamed to replace the `unison-ucm` included in Nixpkgs.
          unison-ucm = localPkgs.ucm;

          vimPlugins = prev.vimPlugins // self.overlays.vim final prev;
        };

        emacs = final: prev: efinal: eprev: {
          unison-ts-mode = let
            version = "1.0.0-rc.2";
          in
            efinal.trivialBuild {
              inherit version;
              pname = "unison-ts-mode";

              src = final.fetchFromGitHub {
                owner = "fmguerreiro";
                repo = "unison-ts-mode";
                rev = "v${version}";
                sha256 = "R3A1z8wzhDCy3KGZ7ZMbAed3VmKwdExsUyxD2X8ZtoM=";
              };
            };
        };

        vim = final: prev: {inherit (localPackages final) vim-unison;};
      };

      ## Deprecated
      overlay = self.overlays.default;

      lib = let
        buildUnisonFromTranscript = pkgs:
          pkgs.callPackage ./nix/build-from-transcript.nix {
            inherit (localPackages pkgs) ucm;
          };
      in {
        inherit buildUnisonFromTranscript;

        buildUnisonShareProject = pkgs:
          pkgs.callPackage ./nix/build-share-project.nix {
            buildUnisonFromTranscript = buildUnisonFromTranscript pkgs;
          };

        ## This is automatically added to the available `tree-sitter` grammars
        ## in the default overlay. However, `extraGrammars` doesn’t compose, so
        ## if another overlay also provides a grammar, one will overwrite the
        ## other. The way around that is to explicitly combine the grammars in a
        ## final overlay,
        ##
        ##    final: prev: {
        ##      tree-sitter = prev.tree-sitter.override {
        ##        extraGrammars =
        ##          unison-nix.lib.tree-sitter-grammars final
        ##          // <grammars from other flakes>;
        ##      };
        ##    }
        tree-sitter-grammars = pkgs: {
          tree-sitter-unison.src =
            pkgs.fetchFromGitHub tree-sitter-unison-github;
        };
      };

      homeConfigurations = builtins.listToAttrs (map (system: {
        name = "${system}-example";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [self.overlays.default];
          };
          modules = [
            ({pkgs, ...}: {
              home = {
                packages = [
                  (pkgs.tree-sitter.withPlugins (tpkgs: [
                    tpkgs.tree-sitter-unison
                  ]))
                  pkgs.unison-ucm
                ];
                stateVersion = "23.11";
                username = "example";
                homeDirectory = "/home/example";
              };
              programs = {
                emacs = {
                  enable = true;
                  extraConfig = ''
                    (use-package eglot
                      :config
                      (add-to-list
                       'eglot-server-programs
                       '((unison-ts-mode unisonlang-mode) "127.0.0.1" 5757)))
                    ;; TODO: This should be made available via
                    ;;      `pkgs.tree-sitter.withPlugins` above, but they
                    ;;       currently don’t align, so you need this, then run
                    ;;      `M-x treesit-install-language-grammar` and select
                    ;;      “unison”.
                    (use-package treesit
                      :config
                      (add-to-list
                       'treesit-language-source-alist
                       '(unison
                         "git@github.com:${tree-sitter-unison-github.owner}/${tree-sitter-unison-github.repo}.git"
                         "${tree-sitter-unison-github.rev}")))
                    (use-package unison-ts-mode)
                  '';
                  extraPackages = epkgs: [epkgs.unison-ts-mode];
                  package = pkgs.emacs29;
                };
                vim = {
                  enable = true;
                  plugins = with pkgs.vimPlugins; [vim-unison];
                };
              };
            })
          ];
        };
      }) ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"]);
    };
}
