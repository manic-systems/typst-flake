{
  description = "Typst builds tracked directly from upstream Git sources";

  outputs =
    {
      self,
      ...
    }@args:
    let
      inputs = (import ./.tack) {
        overrides = args.tackOverrides or { };
      };

      inherit (inputs) nixpkgs;
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;
      pkgsForEach = nixpkgs.legacyPackages;

      inherit (lib.attrsets) listToAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.strings)
        concatStringsSep
        hasPrefix
        removePrefix
        replaceStrings
        splitString
        ;
      inherit (lib.trivial) importJSON importTOML;

      tackManifest = importTOML ./.tack/pins.toml;
      pinsLock = importJSON ./.tack/pins.lock.json;

      typstReleaseInputs = builtins.sort (
        a: b: (pinsLock.${a}.lastModified or 0) > (pinsLock.${b}.lastModified or 0)
      ) (builtins.filter (name: hasPrefix "typst_" name) (builtins.attrNames tackManifest.inputs));

      pinVersion =
        pin:
        let
          parts = splitString "_" (removePrefix "typst_" pin);
          major = builtins.elemAt parts 0;
          minor = builtins.elemAt parts 1;
          patch = builtins.elemAt parts 2;
          prerelease = lib.lists.drop 3 parts;
        in
        if major == "23" then
          concatStringsSep "-" parts
        else
          concatStringsSep "." [
            major
            minor
            patch
          ]
          + lib.optionalString (prerelease != [ ]) "-${concatStringsSep "." prerelease}";

      releaseVersions = map pinVersion typstReleaseInputs;
      latestRelease = builtins.head releaseVersions;

      versionName = version: replaceStrings [ "." "-" "+" ] [ "_" "_" "_" ] version;
      versionAttr = version: "typst-${versionName version}";

      releaseAttrs =
        f:
        listToAttrs (
          map (
            pin:
            let
              version = pinVersion pin;
            in
            {
              name = versionAttr version;
              value = f { inherit pin version; };
            }
          ) typstReleaseInputs
        );
    in
    {
      formatter = forEachSystem (system: pkgsForEach.${system}.nixfmt-tree);

      packages = forEachSystem (
        system:
        let
          pkgs = pkgsForEach.${system};
          typstPackage = pkgs.callPackage ./package.nix { };

          mkTypst =
            args@{ pin, ... }:
            typstPackage (
              args
              // {
                src = inputs.${pin};
                rev = pinsLock.${pin}.rev or "unknown";
              }
            );

          releases = releaseAttrs (
            { pin, version }:
            mkTypst {
              inherit pin version;
            }
          );

          latest = releases.${versionAttr latestRelease};
          master = mkTypst {
            pin = "typst";
            version = latestRelease;
            branch = "main";
          };
        in
        releases
        // {
          default = latest;
          typst = latest;
          "typst-master" = master;
        }
      );

      apps = forEachSystem (
        system:
        let
          packages = self.packages.${system};
        in
        {
          default = {
            type = "app";
            program = getExe packages.default;
          };

          "typst-master" = {
            type = "app";
            program = getExe packages."typst-master";
          };
        }
      );

      checks = forEachSystem (
        system:
        let
          pkgs = pkgsForEach.${system};
        in
        {
          tack-lock = pkgs.runCommand "typst-tack-lock" { nativeBuildInputs = [ pkgs.jq ]; } ''
            jq empty ${./.tack/pins.lock.json}
            touch $out
          '';
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = pkgsForEach.${system};
        in
        {
          default = pkgs.callPackage ./shell.nix {
            tack = inputs.tack.packages.${system}.default;
          };
        }
      );

      overlays.default =
        final: prev:
        let
          packages = self.packages.${final.system};
        in
        releaseAttrs ({ version, ... }: packages.${versionAttr version})
        // {
          typst = packages.typst;
          "typst-master" = packages."typst-master";
        };
    };
}
