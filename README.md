<div align="center">
  <h1 id="header">typst-flake</h1>
  <p>A Nix flake for Typst releases and upstream <code>main</code>.</p>

![GitHub License](https://img.shields.io/github/license/manic-systems/typst-flake)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manic-systems/typst-flake/.github%2Fworkflows%2Fupdate.yml)

</div>

---

This flake tracks Typst source pins in `sources.json` and builds Typst with
nixpkgs' Rust packaging.

- releases are exposed by version, like `.#"0.14.2"`
- the moving upstream branch is exposed as `.#main`
- `default` and `typst` point at the latest pinned release

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
Actions. When `sources.json` changes, CI validates the source catalog and builds
`default` and `main` across the configured runner matrix.
