{
  mkShellNoCC,
  nushell,
}:

mkShellNoCC {
  packages = [
    nushell
  ];
}
