{
  craneLib,
  installShellFiles,
  lib,
  libiconv,
  openssl,
  pkg-config,
  stdenv,
  systems,
}:

{
  src,
  version,
  rev,
  branch ? null,
}:

let
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep hasPrefix substring;

  isMain = branch != null;
  kind = if isMain then "main" else "release";
  shortRev = substring 0 12 rev;
  cargoToml = lib.importTOML "${src}/Cargo.toml";
  cargoVersion = cargoToml.workspace.package.version or version;
  packageVersion = if isMain then "${cargoVersion}-main-${shortRev}" else version;
  pname = if isMain then "typst-main" else "typst";

  rustflags = concatStringsSep " " (
    optionals (stdenv.hostPlatform.rust.rustcTargetSpec == "x86_64-unknown-linux-gnu") [
      "-Clinker-features=-lld"
      "-Clink-self-contained=-linker"
    ]
  );

  sourcePaths = [
    "Cargo.toml"
    "Cargo.lock"
    "rustfmt.toml"
    "crates"
    "docs"
    "tests"
  ];

  cleanSrc = lib.sources.cleanSourceWith {
    inherit src;
    filter = path: _: builtins.any (accepted: hasPrefix "${src}/${accepted}" path) sourcePaths;
  };

  commonArgs = {
    src = cleanSrc;
    inherit pname;
    version = packageVersion;

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ]
    ++ optionals stdenv.isDarwin [
      libiconv
    ];

    env = {
      RUSTFLAGS = rustflags;
    };

    meta = {
      description = "A modern markup-based typesetting system";
      homepage = "https://github.com/typst/typst";
      license = lib.licenses.asl20;
      mainProgram = "typst";
      platforms = systems;
    };
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  checks = {
    fmt = craneLib.cargoFmt commonArgs;

    clippy = craneLib.cargoClippy (
      commonArgs
      // {
        inherit cargoArtifacts;
        cargoClippyExtraArgs = "--workspace -- --deny warnings";
      }
    );

    test = craneLib.cargoTest (
      commonArgs
      // {
        inherit cargoArtifacts;
        cargoTestExtraArgs = "--workspace";
      }
    );
  };
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    cargoExtraArgs = "-p typst-cli";
    doCheck = false;

    nativeBuildInputs = commonArgs.nativeBuildInputs ++ [
      installShellFiles
    ];

    postInstall = ''
      installManPage crates/typst-cli/artifacts/*.1

      installShellCompletion \
        crates/typst-cli/artifacts/typst.{bash,fish} \
        --zsh crates/typst-cli/artifacts/_typst
    '';

    GEN_ARTIFACTS = "artifacts";
    TYPST_COMMIT_SHA = rev;
    TYPST_VERSION = cargoVersion;

    passthru = {
      inherit
        branch
        cargoArtifacts
        cargoVersion
        checks
        commonArgs
        kind
        rev
        rustflags
        ;
    };
  }
)
