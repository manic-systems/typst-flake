{
  craneLib,
  git,
  jq,
  nixfmt-tree,
  nushell,
  rust-analyzer,
  rustPlatform,
  tack,
  typst,
}:

craneLib.devShell {
  checks = typst.passthru.checks;
  inputsFrom = [ typst ];

  RUSTFLAGS = typst.passthru.rustflags;
  RUST_SRC_PATH = rustPlatform.rustLibSrc;

  packages = [
    git
    jq
    nixfmt-tree
    nushell
    rust-analyzer
    tack
  ];
}
