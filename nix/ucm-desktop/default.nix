{
  lib,
  stdenv,
  fetchFromGitHub,
  buildNpmPackage,
  fetchNpmDeps,
  electron,
  elmPackages,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  writeShellApplication,
  elm2nix,
}:

let
  src = fetchFromGitHub {
    owner = "unisonweb";
    repo = "ucm-desktop";
    rev = "v1.4.0";
    hash = "sha256-WvDpJV1FhkanZJwpb5Euw+TYLlpsZe+s1iGHnfAsTjA=";
  };

  # Read ui-core ref ucm-desktop needs from it's elm-git.json
  # This ensures we fetch the exact ui-core version that ucm-desktop expects
  elmGitJson = builtins.fromJSON (builtins.readFile (src + "/elm-git.json"));
  uiCoreRev = elmGitJson.git-dependencies.direct."https://github.com/unisonweb/ui-core";

  # Read Elm version from elm.json
  elmJson = builtins.fromJSON (builtins.readFile (src + "/elm.json"));
  elmVersion = elmJson.elm-version;

  # Fetch ui-core repository which contains its own package.json with katex/mermaid dependencies
  uiCoreSrc = fetchFromGitHub {
    owner = "unisonweb";
    repo = "ui-core";
    rev = uiCoreRev;
    hash = "sha256-Cf1tkgpuR0ZIjuYu9rvXcQXI9iQ1vf5Igr2swpF8X2U=";
  };

  # Fetch npm dependencies for ui-core separately
  uiCoreNpmDeps = fetchNpmDeps {
    name = "ui-core-npm-deps";
    src = uiCoreSrc;
    hash = "sha256-5nomnygH02AHFX3qg/sItMKmahPfcvRJPvTmcHNN+Fw=";
  };
in

buildNpmPackage rec {
  pname = "ucm-desktop";
  version = "1.4.0";

  inherit src;

  npmDepsHash = "sha256-NWRxdwkz1nwdvC8k/SXzpL0ZqcqlnHCd7+ouJ+i8zKQ=";

  makeCacheWritable = true;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
    elmPackages.elm
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    npm_config_ignore_scripts = "true";
    # Prevent electron-forge/packager from trying to download electron
    ELECTRON_OVERRIDE_DIST_PATH = "${electron}/libexec/electron";
    ELECTRON_CUSTOM_DIR = "${electron.version}";
    #  @electron/get environment variables
    ELECTRON_SKIP_SHASUMS = "1";
    electron_config_cache = "${electron}";
  };

  npmFlags = [
    "--legacy-peer-deps"
    "--nodedir=${electron.headers}"
  ];

  preConfigure = ''
    # Create elm-stuff directory structure for git dependencies
    # This needs to be done before npm install so ui-core is available
    mkdir -p elm-stuff/gitdeps/github.com/unisonweb

    # Copy ui-core from the fetched source
    cp -r ${uiCoreSrc} elm-stuff/gitdeps/github.com/unisonweb/ui-core
    chmod -R +w elm-stuff/gitdeps
  '';

  postConfigure = ''
    # Install ui-core npm dependencies (katex and mermaid)
    # This replicates part of what ui-core-install.js from unisonweb/ui-core-scripts does
    export npm_config_cache=${uiCoreNpmDeps}

    cd elm-stuff/gitdeps/github.com/unisonweb/ui-core
    npm ci --offline --legacy-peer-deps --ignore-scripts
    cd -

    # Set up Elm to use offline dependencies using fetchElmDeps
    # This sets up ELM_HOME with all packages from elm-srcs.nix
    # To regenerate elm-srcs.nix and registry.dat, see passthru.updateScript
    ${elmPackages.fetchElmDeps {
      inherit elmVersion;
      elmPackages = import ./elm-srcs.nix;
      registryDat = ./registry.dat;
    }}
  '';

  buildPhase = ''
    runHook preBuild

    # Build webpack bundles without packaging
    # This avoids electron-forge's packaging step which tries to download from GitHub
    npm run package || true  # This will fail at packaging but webpack will have built

    # Check if webpack bundles were created
    if [ ! -d ".webpack" ]; then
      echo "ERROR: Webpack bundles were not created"
      exit 1
    fi

    runHook postBuild
  '';

  installPhase =
    let
      # Wayland flags enable native Wayland support when running on Wayland
      waylandFlags = "\${NIXOS_OZONE_WL:+\${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}";
    in
    ''
      runHook preInstall

      # Copy the webpack output directory directly (no need for asar)
      # The .webpack directory contains the built application
      mkdir -p $out/share/ucm-desktop
      cp -r .webpack/* $out/share/ucm-desktop/

      # Create wrapper script - point directly to the main entry point
      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/ucm-desktop \
        --add-flags $out/share/ucm-desktop/x64/main/index.js \
        --add-flags '${waylandFlags}'

      # Install desktop file
      mkdir -p $out/share/applications
      install -Dm644 ${desktopItem}/share/applications/* $out/share/applications/

      # Install icon
      if [ -f icons/icon.png ]; then
        mkdir -p $out/share/pixmaps
        cp icons/icon.png $out/share/pixmaps/ucm-desktop.png
      fi

      runHook postInstall
    '';

  desktopItem = makeDesktopItem {
    name = "ucm-desktop";
    desktopName = "UCM Desktop";
    comment = "Companion app to the Unison programming language";
    exec = "ucm-desktop %U";
    icon = "ucm-desktop";
    categories = [ "Development" ];
  };

  # Update script to regenerate Elm dependencies when elm.json changes
  # First update the three src fetches (two fetchFromGitHub and one fetchNpmDeps)
  # Then run this from the repo root: nix run .#ucm-desktop.updateScript
  passthru.updateScript = writeShellApplication {
    name = "update-ucm-desktop-elm-deps";
    runtimeInputs = [ elm2nix ];
    text = ''
      PACKAGE_DIR="nix/ucm-desktop"

      if [ ! -d "$PACKAGE_DIR" ]; then
        echo "Error: Could not find package directory $PACKAGE_DIR"
        echo "Please run this script from the unison-nix root directory"
        exit 1
      fi

      # Save the current directory
      REPO_ROOT="$(pwd)"

      # Create temporary directory
      TMPDIR=$(mktemp -d)
      trap 'rm -rf $TMPDIR' EXIT

      # Clone the ucm-desktop repository at the version specified in the derivation
      cd "$TMPDIR"
      git clone --depth 1 --branch v${lib.escapeShellArg version} https://github.com/unisonweb/ucm-desktop.git
      cd ucm-desktop

      # Generate elm-srcs.nix (Elm package hashes) and registry.dat (Elm package registry)
      elm2nix convert > elm-srcs.nix
      elm2nix snapshot > /dev/null

      # Copy generated files back to unison-nix
      cp elm-srcs.nix "$REPO_ROOT/$PACKAGE_DIR/"
      cp registry.dat "$REPO_ROOT/$PACKAGE_DIR/"

      echo "Successfully updated elm-srcs.nix and registry.dat"
    '';
  };

  meta = with lib; {
    description = "Companion app to the Unison programming language";
    homepage = "https://unison-lang.org";
    license = licenses.mit;
    maintainers = with lib.maintainers; [ giodamelio ];
    platforms = platforms.linux;
    mainProgram = "ucm-desktop";
  };
}
