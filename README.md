# unison-nix

[Nix] support for the [Unison] programming language

## installation

### 1. install Nix

If you don't already have Nix installed, follow [the instructions on the Nix site](https://nixos.org/download.html).

### 2. add the Unison Nix channel

This is the easiest way to fetch the latest Nix support for Unison.

```sh
nix-channel --add https://github.com/ceedubs/unison-nix/archive/trunk.tar.gz unison
nix-channel --update unison
```

### 3. install Unison code manager

```sh
nix-env -f '<unison>' -i -A unison-ucm
```

You can verify that installation was successful by running `ucm --version`.

If you have [added the Unison nixpkgs overlay](#1.-add-the-unison-nixpkgs-overlay), then you could instead run `nix-env -i -A nixpkgs.unison-ucm`.

## try Unison out in a virtual environment

It's possible to run the Unison code manager in a "virtual environment" that won't add `ucm` to your user `$PATH`. This can also be used to try out a newer version of `ucm` without clobbering an existing older version of `ucm` that you might have installed.

### 1. add the Unison nixpkgs overlay


⚠️  The step below requires that you [add the Unison Nix channel](#2.-add-the-unison-nix-channel) first. ⚠️

```
echo '(import <unison>}).overlay' > ~/.config/nixpkgs/overlays/unison.nix
```

Adding this overlay isn't strictly necessary, but it makes it easier to drop into a `ucm` shell.

### 2. run the Unison code manager

```sh
nix-shell -p unison-ucm --command ucm
```

## available packages

* `unison-ucm`: the Unison code manager
* `vim-unison`: a vim plugin providing syntax highlighting for Unison files
* `unison-stack`: includes the dependencies (such as [Stack]) necessary to build Unison from source (useful as a development environment for working on the Unison compiler)

In the future this repository would be a natural home for derivations for other Unison tools such as a language server.

## FAQ

*Fabricated/Anticipated Questions*

### Why don't these derivations live in nixpkgs?

The [nixpkgs repository][nixpkgs] was the original home of Unison Nix dervations, but Unison is evolving quickly and getting Unison updates merged into nixpkgs turned out to be a bottleneck in getting these new features and bug fixes out to Unison users.

[Nix]: https://nixos.org/
[nixpkgs]: https://github.com/nixos/nixpkgs
[Stack]: https://docs.haskellstack.org/en/stable/README/
[Unison]: https://www.unisonweb.org/
