{
  git,
  jq,
  mkShell,
  nixfmt-tree,
  nushell,
  rust-analyzer,
  rustPlatform,
  typst,
}:

mkShell {
  inputsFrom = [ typst ];

  RUSTFLAGS = typst.passthru.rustflags;
  RUST_SRC_PATH = rustPlatform.rustLibSrc;

  packages = [
    git
    jq
    nixfmt-tree
    nushell
    rust-analyzer
  ];
}
