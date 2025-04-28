### An example Home Manager configuration with Unison set up as many ways as
### possible.
###
### Search for “→” to see the important bits.
{
  pkgs,
  ## → This argument is made available to the configuration via the
  ##  `extraSpecialArgs` field in the flake’s `homeConfigurations` output.
  unison,
  ...
}: {
  nixpkgs.overlays = [
    ## → Make all of the Unison-enriched derivations available.
    unison.overlays.default
  ];

  home.packages = [
    ## → Install tree-sitter with the Unison grammar.
    (pkgs.tree-sitter.withPlugins (tpkgs: [
      tpkgs.tree-sitter-unison
    ]))

    ## → Install the Unison Codebase Manager itself.
    pkgs.unison-ucm
  ];

  programs.emacs = {
    enable = true;
    extraConfig = ''
      ;; → Set up LSP for Unison.
      (use-package eglot
        :config
        (add-to-list
         'eglot-server-programs
         '((unison-ts-mode unisonlang-mode) "127.0.0.1" 5757)))

      ;; → Enable the Emacs treesit package with the Unison grammar.
      (use-package treesit
        :config
        ;; TODO: This should be made available via
        ;;      `pkgs.tree-sitter.withPlugins` above, but they currently don’t
        ;;       align, so you need this.
        (add-to-list
         'treesit-language-source-alist
         '${unison.lib.emacsTreesitLanguageSource})
        (treesit-install-language-grammar 'unison))

      ;; → Enable the Unison Emacs mode.
      (use-package unison-ts-mode)
    '';
    extraPackages = epkgs: [
      ## → Install the Unison Emacs mode.
      epkgs.unison-ts-mode
    ];
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      ## → Install the Neovim treesitter plugin with the Unison grammar.
      (nvim-treesitter.withPlugins (tspkgs: [tspkgs.unison]))
    ];
  };

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      ## → Install the Vim Unison plugin.
      vim-unison
    ];
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ## → Install the VS Code Unison extensions.
      unison-lang.unison
      TomSherman.unison-ui
    ];
    package = pkgs.vscodium; # To avoid needing unfree packages.
    ## → Configure the VS Code Unison extension.
    userSettings."unison.lspPort" = 1234;
  };

  ## Unimportant configuration needed by Home Manager.
  home = {
    stateVersion = "24.11";
    username = "example";
    homeDirectory = "/home/example";
  };
}
