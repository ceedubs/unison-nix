let
  unisonPkgs = import nix/default.nix {};
in
unisonPkgs // {
  overlay = import ./nix/overlay.nix;
}
