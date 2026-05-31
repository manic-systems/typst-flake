{
  git,
  jq,
  mkShellNoCC,
  nixfmt-tree,
  tack,
}:
mkShellNoCC {
  strictDeps = true;
  packages = [
    git
    jq
    nixfmt-tree
    tack
  ];
}
