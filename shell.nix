{
  mkShellNoCC,
  nushell,
}:

mkShellNoCC {
  buildInputs = [
    nushell
  ];
}
