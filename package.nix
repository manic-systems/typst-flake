{
  installShellFiles,
  lib,
  libiconv,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
  src,
  version,
  rev,
  branch ? null,
}:

let
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep substring;

  isMain = branch != null;
  kind = if isMain then "main" else "release";
  shortRev = substring 0 12 rev;
  cargoToml = lib.importTOML "${src}/Cargo.toml";
  cargoVersion = cargoToml.workspace.package.version or version;
  packageVersion = if isMain then "${cargoVersion}-main-${shortRev}" else version;

  rustflags = concatStringsSep " " (
    optionals (stdenv.hostPlatform.rust.rustcTargetSpec == "x86_64-unknown-linux-gnu") [
      "-Clinker-features=-lld"
      "-Clink-self-contained=-linker"
    ]
  );

in
rustPlatform.buildRustPackage {
  inherit src;
  pname = "typst";
  version = packageVersion;

  strictDeps = true;

  buildInputs = [
    openssl
  ]
  ++ optionals stdenv.isDarwin [
    libiconv
  ];

  env = {
    RUSTFLAGS = rustflags;
  };

  cargoBuildFlags = [
    "-p"
    "typst-cli"
  ];
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  doCheck = false;

  nativeBuildInputs = [
    installShellFiles
    pkg-config
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
      cargoVersion
      kind
      rev
      rustflags
      ;
  };

  meta = {
    description = "A modern markup-based typesetting system";
    homepage = "https://github.com/typst/typst";
    license = lib.licenses.asl20;
    mainProgram = "typst";
  };
}
