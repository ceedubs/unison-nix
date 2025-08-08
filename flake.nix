{
  description = "Support for the Unison programming language";

   nixConfig = {
    extra-substituters = ["https://unison.cachix.org"];
    extra-trusted-public-keys = [
      "unison.cachix.org-1:i1DUFkisRPVOyLp/vblDsbsObmyCviq/zs6eRuzth3k="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-24.11";
    };
    unison = {
      ## NB: This doesn’t override Nixpkgs, because Unison relies heavily on
      ##     haskell.nix and its own Cachix cache.
      inputs.flake-utils.follows = "flake-utils";
      ## NB: Before upgrading this, make sure the release you upgrade to is
      ##     pinned in the cache (https://app.cachix.org/cache/unison#pins) for
      ##     all supported systems.
      url = "github:unisonweb/unison/5e7bd7c4bfe6a1c2ddbcd3d35b7281ef7b1fa10e";
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
      rev = "2.0.1";
      hash = "sha256-0HOLtLh1zRdaGQqchT5zFegWKJHkQe9r7DGKL6sSkPo=";
    };

    local = {
      packages = pkgs: let
      darwin-security-hack = pkgs.callPackage ./nix/darwin-security-hack.nix {};
    in {
      ucm = unison.packages.${pkgs.system}.default;

      ucm-bin = pkgs.callPackage ./nix/ucm.nix {inherit darwin-security-hack;};

      tree-sitter-grammar = pkgs.tree-sitter.buildGrammar {
        language = "unison";
        version = tree-sitter-unison-github.rev;
        src = pkgs.fetchFromGitHub tree-sitter-unison-github;
      };

      ## TODO: Move this to Unison proper, and then just re-export it from here.
      ##       Then we can avoid the non-flake usage of the Unison flake.
      vim-unison = pkgs.vimUtils.buildVimPlugin {
        name = "vim-unison";
        src = unison + "/editor-support/vim";
      };

      vscode-lang = pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "unison";
        publisher = "unison-lang";
        version = "1.2.0";
        hash = "sha256-ulm3a1xJxtk+SIQP1sByEqgajd1a4P3oEfVgxoF5GcQ=";
      };

      vscode-ui = pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "unison-ui";
        publisher = "TomSherman";
        version = "0.1.5";
        hash = "sha256-PrbeIxhHWas35XfGnVSEMh4rH4uk+4Sls6syj4H29eQ=";
      };
    };

      packagesLib = pkgs: let
        buildFromTranscript =
          pkgs.callPackage ./nix/build-from-transcript.nix {
            ucm = (local.packages pkgs).ucm-bin;
          };
      in {
        inherit buildFromTranscript;

        buildShareProject =
          pkgs.callPackage ./nix/build-share-project.nix {
            inherit buildFromTranscript;
          };
      };
    };
  in
    flake-utils.lib.eachSystem systems
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages =
          {default = self.packages.${system}.ucm-bin;} // local.packages pkgs;
        packagesLib = local.packagesLib pkgs;

        ## Deprecated
        defaultPackage = self.packages.${system}.default;

        checks = {
          # A simple example: create an executable from a Unison Share project
          snake = let
            newPkgs = pkgs.appendOverlays [self.overlays.default];
          in newPkgs.unison.lib.buildShareProject {
            pname = "snake";
            version = "0.0.4";
            userHandle = "runarorama";
            projectName = "terminus";

            # The compiledHash is the hash of the compiled Unison code. This
            # is needed because Nix builds restrict network access unless the
            # output hash is known ahead of time (which helps with
            # reproducibility and caching). You won't know it until you run
            # the derivation for the first time. You can just set this to
            # `pkgs.lib.fakeHash` and do a `nix build` or `nix run` and copy
            # the hash labeled `got: `.
            compiledHash = "sha256-ifoZGxIBjCO6A+DgwmAUOzfRaiXr0w/ReVbY1vLjIG8=";

            # A mapping of executable names to Unison functions.
            executables = {"snake" = "examples.snake.main";};
          };
        };

        formatter = pkgs.alejandra;
      }
    )
    // {
      overlays = {
        default = final: prev: let
          localPkgs = local.packages final;
        in {
          emacsPackagesFor = emacs:
            (prev.emacsPackagesFor emacs).overrideScope
            (self.overlays.emacs final prev);

          tree-sitter = prev.tree-sitter.override {
            extraGrammars = self.overlays.tree-sitter final prev;
          };

          unison.lib = local.packagesLib final;

          ## Renamed to replace the `unison-ucm` included in Nixpkgs.
          unison-ucm = localPkgs.ucm-bin;

          vimPlugins =
            prev.vimPlugins // self.overlays.vim final prev prev.vimPlugins;

          vscode-extensions =
            prev.vscode-extensions // self.overlays.vscode final prev;
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
                hash = "sha256-R3A1z8wzhDCy3KGZ7ZMbAed3VmKwdExsUyxD2X8ZtoM=";
              };
            };
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
        ##          unison.overlays.tree-sitter final prev
        ##          // <grammars from other flakes>;
        ##      };
        ##    }
        ##
        ## NB: tree-sitter doesn’t seem to be able to take grammar derivations,
        ##     so we give it the source.
        tree-sitter = final: prev: {
          tree-sitter-unison.src =
            final.fetchFromGitHub tree-sitter-unison-github;
        };

        vim = final: prev: vpkgs: let
          localPkgs = local.packages final;
        in {
          inherit (localPkgs) vim-unison;

          nvim-treesitter = vpkgs.nvim-treesitter.overrideAttrs (old: {
            builtGrammars =
              old.builtGrammars
              // {
                unison = localPkgs.tree-sitter-grammar;
              };
          });
        };

        vscode = final: prev: let
          localPkgs = local.packages final;
        in {
          TomSherman.unison-ui = localPkgs.vscode-ui;
          unison-lang.unison = localPkgs.vscode-lang;
        };
      };

      ## Deprecated
      overlay = self.overlays.default;

      lib = {
        ## Emacs’s `treesit` package wants to pull grammars from Git repos, so
        ## this provides the Emacs Lisp form to pull the same grammer packaged
        ## in this flake.
        ##
        ## See ./nix/home.nix for example usage.
        ##
        ## TODO: Convince Emacs to use the packaged grammar.
        emacsTreesitLanguageSource = ''
          (unison
           "git@github.com:${tree-sitter-unison-github.owner}/${tree-sitter-unison-github.repo}.git"
           "${tree-sitter-unison-github.rev}")
        '';
      };

      homeConfigurations = builtins.listToAttrs (map (system: {
        name = "${system}-example";
        value = home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs.unison = self;
          modules = [./nix/home.nix];
          pkgs = nixpkgs.legacyPackages.${system};
        };
      }) ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"]);
    };
}
