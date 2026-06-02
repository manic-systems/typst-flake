{
  description = "Typst builds tracked directly from upstream Git sources";

  outputs =
    { self, ... }:
    let
      inputs = import ./.tack;

      inherit (inputs) nixpkgs;
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = lib.genAttrs systems;
      pkgsForEach = nixpkgs.legacyPackages;

      inherit (lib.attrsets) mapAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.trivial) importJSON;

      sources = importJSON ./sources.json;
      latestRelease = sources.latest;

      perSystem = forEachSystem (
        system:
        let
          pkgs = pkgsForEach.${system};
          craneLib = inputs.crane.mkLib pkgs;

          mkTypst =
            {
              source,
              version,
              branch ? null,
            }:
            pkgs.callPackage ./package.nix
              {
                inherit craneLib systems;
              }
              {
                src = fetchTree source;
                rev = source.rev or "unknown";
                inherit branch version;
              };

          releases = mapAttrs (
            version: source:
            mkTypst {
              inherit source version;
            }
          ) sources.versions;

          latest = releases.${latestRelease};
          mainPackage = mkTypst {
            source = sources.main;
            version = latestRelease;
            branch = "main";
          };

          mkApp = package: {
            type = "app";
            program = getExe package;
          };
        in
        {
          packages = releases // {
            default = latest;
            typst = latest;
            main = mainPackage;
            "typst-main" = mainPackage;
          };

          checks = {
            sources-json = pkgs.runCommand "typst-sources-json" { nativeBuildInputs = [ pkgs.jq ]; } ''
              jq empty ${./sources.json}
              touch $out
            '';

            tack-lock = pkgs.runCommand "typst-tack-lock" { nativeBuildInputs = [ pkgs.jq ]; } ''
              jq empty ${./.tack/pins.lock.json}
              touch $out
            '';

            typst-fmt = latest.passthru.checks.fmt;
            typst-clippy = latest.passthru.checks.clippy;
            typst-test = latest.passthru.checks.test;
          };

          devShells.default = pkgs.callPackage ./shell.nix {
            inherit craneLib;
            tack = inputs.tack.packages.${system}.default;
            typst = mainPackage;
          };

          apps = {
            default = mkApp latest;
            main = mkApp mainPackage;
          };
        }
      );
    in
    {
      formatter = forEachSystem (system: pkgsForEach.${system}.nixfmt-tree);

      packages = mapAttrs (_: value: value.packages) perSystem;

      apps = mapAttrs (_: value: value.apps) perSystem;

      checks = mapAttrs (_: value: value.checks) perSystem;

      devShells = mapAttrs (_: value: value.devShells) perSystem;

      overlays.default =
        final: prev:
        let
          packages = self.packages.${final.system};
        in
        {
          typst = packages.default;
          typstpkgs = packages;
          "typst-main" = packages.main;
        };
    };
}
