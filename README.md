<div align="center">
  <h1 id="header">typst-flake</h1>
  <p>A Nix flake for Typst releases and upstream <code>main</code>.</p>

![GitHub License](https://img.shields.io/github/license/manic-systems/typst-flake)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manic-systems/typst-flake/.github%2Fworkflows%2Fupdate.yml)

</div>

---

This flake tracks Typst source pins in `sources.json` and builds Typst with Crane.

- release outputs are inferred from `sources.json`
- releases are exposed by version, like `.#"0.14.2"`
- the moving upstream branch is exposed as `.#main`
- `default` and `typst` point at the latest pinned release

The Rust toolchain comes from the pinned `nixpkgs`; with the current pin that is
Rust/Cargo `1.95.0`.

## Packages

Build the latest pinned release:

```sh
nix build .#default
nix build .#typst
```

Build a specific release:

```sh
nix build '.#"0.14.2"'
```

Build upstream `main`:

```sh
nix build .#main
```

`typst-main` is kept as an alias for `main`:

```sh
nix build .#typst-main
```

Run Typst from the flake:

```sh
nix run .#default -- --version
nix run .#main -- --version
nix run '.#"0.14.2"' -- --version
```

## Checks

Crane exposes Typst checks for the latest pinned release:

```sh
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
nix build ".#checks.${system}.typst-fmt" --no-link
nix build ".#checks.${system}.typst-clippy" --no-link
nix build ".#checks.${system}.typst-test" --no-link
```

There are also lightweight JSON checks for the Typst source catalog and Tack
tooling pins:

```sh
system="$(nix eval --impure --raw --expr builtins.currentSystem)"
nix build ".#checks.${system}.sources-json" --no-link
nix build ".#checks.${system}.tack-lock" --no-link
```

## Overlay

The default overlay exposes `typst`, `typst-main`, and a `typstpkgs` namespace
containing every versioned package output:

```nix
{
  inputs.typst-flake.url = "github:manic-systems/typst-flake";

  outputs =
    { nixpkgs, typst-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ typst-flake.overlays.default ];
      };
    in
    {
      packages.${system}.default = pkgs.typst;
      packages.${system}.typst-main = pkgs.typstpkgs.main;
      packages.${system}.typst-0_14_2 = pkgs.typstpkgs."0.14.2";
    };
}
```

## Updating

Enter the development shell:

```sh
nix develop
```

Update upstream `main` and add any missing Typst release tags:

```sh
nu scripts/update-sources.nu
```

Typst source pins live in `sources.json`:

```json
{
  "latest": "0.14.2",
  "main": {
    "type": "github",
    "owner": "typst",
    "repo": "typst"
  },
  "versions": {
    "0.14.2": {
      "type": "git",
      "url": "https://github.com/typst/typst.git",
      "ref": "refs/tags/v0.14.2"
    }
  }
}
```

The update workflow runs weekly and can also be triggered manually from GitHub
Actions. When `sources.json` changes, CI validates the source catalog and Tack
lock, builds `default` and `main` across the configured runner matrix, and runs
the Typst Crane checks on `ubuntu-latest`.
