{ sources, pkgs, haskellPackages, haskell }:
let
  inherit (haskell.lib) dontCheck doJailbreak overrideCabal;
  overrides =
    self: super: {
      easytest = self.callCabal2nix "easytest" "${sources.unison}/yaks/easytest" {};
      unison-core = doJailbreak (self.callCabal2nix "unison-core" "${sources.unison}/unison-core" {});
      unison-parser-typechecker = overrideCabal (doJailbreak (self.callCabal2nix "unison-parser-typechecker" "${sources.unison}/parser-typechecker" {}))
        {
          configureFlags = [ "--constraint=haskeline==0.7.5.0" ];
        };
      random = dontCheck self.random_1_2_0;
      hashable = doJailbreak super.hashable;
      unicode-show = dontCheck super.unicode-show;
      megaparsec = dontCheck (doJailbreak (self.callCabal2nix "megaparsec" sources.megaparsec {}));
      haskeline = doJailbreak (self.callCabal2nix "haskeline" sources.haskeline {});
    };
  myHaskellPackages = haskellPackages.override {
    inherit overrides;
  };
in
myHaskellPackages.unison-parser-typechecker
