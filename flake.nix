{
  description = "CL-CC parse features and parser adapters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    cl-cc-ast = {
      url = "github:nerima-lisp/cl-cc-ast/a45c5acecfccb91a43f6a04251e8a5d6ec3d3213";
      flake = false;
    };
    cl-cc-bootstrap = {
      url = "github:nerima-lisp/cl-cc-bootstrap/027f6c9826010c15789454e69abd2930738b50af";
      flake = false;
    };
    cl-parser-kit = {
      url = "github:nerima-lisp/cl-parser-kit/aad0f88727940ff3f4e8674943e3faa240206f45";
      flake = false;
    };
    cl-weave = {
      url = "github:nerima-lisp/cl-weave/v1.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cl-nix-forge.follows = "cl-nix-forge";
    };
    cl-nix-forge = {
      url = "github:nerima-lisp/cl-nix-forge/950a8224940539a97c112a6b872f0ae5b6c115db";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      cl-cc-ast,
      cl-cc-bootstrap,
      cl-parser-kit,
      cl-weave,
      cl-nix-forge,
      treefmt-nix,
      ...
    }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];
      sourceRegistry =
        "${cl-weave}//:${cl-cc-ast}//:${cl-cc-bootstrap}//:${cl-parser-kit}//:${self}//";
    in
    cl-nix-forge.lib.${builtins.head systems}.mkPackageFlake {
      inherit self nixpkgs systems;
      pname = "cl-cc-parse";
      asd = ./cl-cc-parse.asd;
      root = ./.;
      sourceInclude = [ ./t/export-surface.txt ];

      meta = {
        description = "CL-CC parse features and parser adapters";
        homepage = "https://github.com/nerima-lisp/cl-cc-parse";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };

      packageArgs = _: {
        CL_SOURCE_REGISTRY = sourceRegistry;
      };
      timeoutSeconds = 120;
      killAfterSeconds = 15;
      treefmt.evalModule = treefmt-nix.lib.evalModule;

      extraOutputs =
        ctx: {
          checks.feature-lint = ctx.cl.mkFeatureLintCheck {
            src = ./.;
            featureDefinitions = "nix/feature-dependencies.sexp";
            glossary = "docs/src/reference/glossary.md";
            glossaryHeadingPrefix = "## ";
            exportSurface = "t/export-surface.txt";
            mode = "transition";
            legacyInternalRefs = "t/legacy-internal-refs.sexp";
            forbiddenNames = [ "phases" "misc" "utils" "helpers" ];
            numberedPrefixes = [ "FR-" "W" ];
            packagePrefix = "cl-cc/parse/";
            infraSuffix = "/infra";
          };
          checks.orphan-tests = ctx.cl.mkOrphanTestCheck {
            src = ./.;
            testRoots = [ "t" ];
            testSystems = [ "cl-cc-parse/test" ];
          };
        };
    };
}
