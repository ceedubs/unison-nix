self: super:

let
  unisonPkgs = import ./default.nix { pkgs = super; };
in
{
  inherit (unisonPkgs) unison-ucm unison-stack;

  vimPlugins = super.vimPlugins // {
    inherit (unisonPkgs) vim-unison;
  };
}
