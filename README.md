# unison-nix

[Nix] support for the [Unison] programming language

## usage

**NOTE:** If you don't already have Nix installed, follow [the instructions on the Nix site](https://nixos.org/download.html).

### install Unison code manager

**If your version of Nix supports [Nix flakes]**:

```
nix profile install github:ceedubs/unison-nix#ucm-bin
```

**Use from home-manager:**

In your home-manager's `flake.nix`, reference this repository under `inputs`, e.g.:

```nix
unison-lang = {
  url = "github:ceedubs/unison-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

then add the unison-lang overlay:

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ unison-lang.overlay ];
};
```

Finally, in your `home.nix`, just add the `unison-ucm` package as you normally would.

An example is available [here](https://github.com/bbarker/dotfiles/tree/6b0c9c2b5a59e55a4a25700fe0833e5a95d7f84c).

**Older versions of Nix:**

```
nix-env -iA unison-ucm -f https://github.com/ceedubs/unison-nix/archive/trunk.tar.gz
```

### try out Unison without installing it to your PATH/Nix profile

**If your version of Nix supports [Nix flakes]:**

```
nix run github:ceedubs/unison-nix#ucm-bin
```

**Older versions of Nix:**

```
nix-build https://github.com/ceedubs/unison-nix/archive/trunk.tar.gz -A unison-ucm
```

This will create a symlink named `result` in your current directory. Now run:

```sh
./result/bin/ucm
```

Once you are done trying out Unison you can `rm ./result`.

## available packages/tools

* `ucm-bin`: a binary release of the Unison code manager
  * This is named `unison-ucm` in the overlay and for older versions of Nix (pre-flakes)
* `ucm`: a release of the Unison code manager built from source (without some of the niceties provided by `ucm-bin`)
* `vim-unison`: a vim plugin providing syntax highlighting for Unison files
  * This is provided as `vimPlugins.vim-unison` in the overlay
* VS Code extensions
  * [unison-lang.unison](https://marketplace.visualstudio.com/items?itemName=unison-lang.unison) – the official extension from the [Unison](https://www.unison-lang.org/) team, provides syntax highlighting and LSP support
  * [TomSherman.unison-ui](https://marketplace.visualstudio.com/items?itemName=TomSherman.unison-ui) – adds a codebase explorer sidebar
* `overlay`: A nixpkgs overlay that adds the Unison packages in the relevant places (ex: `vim-unison` in `vimPlugins.vim-unison`)
* `buildUnisonShareProject` a function for turning functions in a Unison Share project into executable derivations.
  * See [unison-nix-snake](https://github.com/ceedubs/unison-nix-snake) for an example.
  * See [nix/build-share-project.nix](nix/build-share-project.nix) for documentation.
* `buildUnisonFromTranscript` a lower-level function for turning a Unison transcript into an executable derivation.
  * See [nix/build-from-transcript.nix](nix/build-from-transcript.nix) for documentation.

In the future this repository would be a natural home for derivations for other Unison tools.

**NOTE**: the [unison github repo](https://github.com/unisonweb/unison) repo has a `flake.nix` that you can use with `nix develop` to get an environment with the expected versions of `stack`, `ormolu`, etc.

## FAQ

*Fabricated/Anticipated Questions*

### Why don't these derivations live in nixpkgs?

The [nixpkgs repository][nixpkgs] was the original home of Unison Nix dervations, but Unison is evolving quickly and getting Unison updates merged into nixpkgs turned out to be a bottleneck in getting these new features and bug fixes out to Unison users.

[Nix]: https://nixos.org/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[nixpkgs]: https://github.com/nixos/nixpkgs
[Stack]: https://docs.haskellstack.org/en/stable/README/
[Unison]: https://www.unisonweb.org/
