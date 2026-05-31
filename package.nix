{
  installShellFiles,
  lib,
  libiconv,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
}:

{
  src,
  pin,
  version,
  rev,
  branch ? null,
}:

let
  inherit (lib.lists) optionals;
  inherit (lib.strings) concatStringsSep substring;

  isMaster = branch != null;
  kind = if isMaster then "master" else "release";
  shortRev = substring 0 12 rev;
  cargoToml = lib.importTOML "${src}/Cargo.toml";
  cargoVersion = cargoToml.workspace.package.version or version;
  packageVersion = if isMaster then "${cargoVersion}-master-${shortRev}" else version;

  rustflags = concatStringsSep " " (
    optionals (stdenv.hostPlatform.rust.rustcTargetSpec == "x86_64-unknown-linux-gnu") [
      "-Clinker-features=-lld"
      "-Clink-self-contained=-linker"
    ]
  );
in
rustPlatform.buildRustPackage {
  pname = if isMaster then "typst-master" else "typst";
  version = packageVersion;

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    # Typst's lockfile contains pinned git dependencies, and maintaining
    # outputHashes for every historical release would duplicate Cargo.lock.
    allowBuiltinFetchGit = true;
  };
  cargoBuildFlags = [
    "-p"
    "typst-cli"
  ];

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ optionals stdenv.isDarwin [
    libiconv
  ];

  doCheck = false;

  env = {
    GEN_ARTIFACTS = "artifacts";
    TYPST_COMMIT_SHA = rev;
    TYPST_VERSION = cargoVersion;
  }
  // lib.optionalAttrs (rustflags != "") {
    RUSTFLAGS = rustflags;
  };

  postInstall = ''
    shopt -s nullglob

    manpages=(crates/typst-cli/artifacts/*.1)
    if [ "''${#manpages[@]}" -gt 0 ]; then
      installManPage "''${manpages[@]}"
    fi

    completions=(crates/typst-cli/artifacts/typst.{bash,fish})
    zsh_completion=crates/typst-cli/artifacts/_typst
    if [ "''${#completions[@]}" -gt 0 ] && [ -f "$zsh_completion" ]; then
      installShellCompletion "''${completions[@]}" --zsh "$zsh_completion"
    fi
  '';

  passthru = {
    inherit
      branch
      kind
      pin
      rev
      ;
  };

  meta = {
    description = "A modern markup-based typesetting system";
    homepage = "https://github.com/typst/typst";
    license = lib.licenses.asl20;
    mainProgram = "typst";
    platforms = lib.systems.flakeExposed;
  };
}
