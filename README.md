<div align="center">
  <h1 id="header">typst-flake</h1>
  <p>A Nix flake for Typst releases and upstream <code>main</code>.</p>

![GitHub License](https://img.shields.io/github/license/manic-systems/typst-flake)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manic-systems/typst-flake/.github%2Fworkflows%2Fupdate.yml)

</div>

---

This is a simple project, tracking upstream Typst and exposing an auto-updating flake for _all_ typst releases and the moving `main` branch.
The flake tracks Typst source pins in `sources.json` and builds Typst with nixpkgs' Rust packaging. Typst releases are exposed by version, e.g. `.#"0.14.2"`. The continuously moving `main` branch is exposed as `.#main`; the latest pinned release is exposed as `.#default` and `.#typst`.

Typst itself used to house a flake in the main repo, but it was [dropped in early 2026](https://github.com/typst/typst/pull/7512). An "offical" flake continues to live at
<https://github.com/typst/typst-flake>, but that one only tracks the latest pinned release, as opposed to this project, which also exposes the current `main` branch.

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

Run Typst from the flake:

```sh
nix run .#default -- --version
nix run .#main -- --version
nix run '.#"0.14.2"' -- --version
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

The Typst source pins are located in `sources.json`:

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
