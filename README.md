# unison-nix

[Nix] support for the [Unison] programming language

## usage

**NOTE:** If you don't already have Nix installed, follow [the instructions on the Nix site](https://nixos.org/download.html).

### install Unison code manager

**If your version of Nix supports [Nix flakes]**:

```
nix profile install github:ceedubs/unison-nix#ucm
```

**Older versions of Nix:**

```
nix-env -iA unison-ucm -f https://github.com/ceedubs/unison-nix/archive/trunk.tar.gz
```

### try out Unison without installing it to your PATH/Nix profile

**If your version of Nix supports [Nix flakes]:**

```
nix run github:ceedubs/unison-nix#ucm
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

* `ucm`: the Unison code manager
  * This is named `unison-ucm` in the overlay and for older versions of Nix (pre-flakes)
* `vim-unison`: a vim plugin providing syntax highlighting for Unison files
  * This is provided as `vimPlugins.vim-unison` in the overlay
* `unison-stack` (experimental): includes the dependencies (such as [Stack]) necessary to build Unison from source (useful as a development environment for working on the Unison compiler). To use:
  * `nix develop github:ceedubs/unison-nix`
  * `stack build`, `stack exec tests`, etc.
* `overlay`: A nixpkgs overlay that adds the Unison packages is the relevant places (ex: `vim-unison` in `vimPlugins.vim-unison`)

In the future this repository would be a natural home for derivations for other Unison tools such as a language server.

## FAQ

*Fabricated/Anticipated Questions*

### Why don't these derivations live in nixpkgs?

The [nixpkgs repository][nixpkgs] was the original home of Unison Nix dervations, but Unison is evolving quickly and getting Unison updates merged into nixpkgs turned out to be a bottleneck in getting these new features and bug fixes out to Unison users.

[Nix]: https://nixos.org/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[nixpkgs]: https://github.com/nixos/nixpkgs
[Stack]: https://docs.haskellstack.org/en/stable/README/
[Unison]: https://www.unisonweb.org/
