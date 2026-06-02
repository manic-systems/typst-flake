{
  description = "Typst builds tracked directly from upstream Git sources";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib) genAttrs;
      inherit (lib.attrsets) mapAttrs;
      inherit (lib.trivial) importJSON;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSystem = genAttrs systems;
      pkgsForEach = inputs.nixpkgs.legacyPackages;

      sources = importJSON ./sources.json;
      latestRelease = sources.latest;
    in
    {
      formatter = forEachSystem (system: pkgsForEach.${system}.nixfmt);

      packages = forEachSystem (
        system:
        let
          pkgs = pkgsForEach.${system};

          releases = mapAttrs (
            version: source:
            pkgs.callPackage ./package.nix {
              src = fetchTree source;
              rev = source.rev or "unknown";
              inherit version;
            }
          ) sources.versions;

          latest = releases.${latestRelease};
        in
        {
          default = latest;
          typst = latest;

          main = pkgs.callPackage ./package.nix {
            src = fetchTree sources.main;
            rev = sources.main.rev or "unknown";
            version = latestRelease;
          };
        }
        // releases
      );
    };
}
