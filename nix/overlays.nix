let
  makeOverlay = unisonPkgs: self: super:
    {
      inherit (unisonPkgs) unison-ucm unison-stack;

      vimPlugins = super.vimPlugins // {
        inherit (unisonPkgs) vim-unison;
      };
    };
in
{
  overlay = self: super: makeOverlay (import ./default.nix { pkgs = super; }) self super;
  pinnedOverlay = makeOverlay (import ./default.nix {});
}
