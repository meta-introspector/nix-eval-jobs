{
  description = "Hydra's builtin hydra-eval-jobs as a standalone";

  # Switch back after https://nixpk.gs/pr-tracker.html?pr=396710 is finished
  # inputs.nixpkgs.url = "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.nix = {
    url = "github:NixOS/nix/2.30-maintenance";
    # We want to control the deps precisely
    flake = false;
  };
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs) self;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "riscv64-linux"
        "x86_64-linux"

        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        { pkgs, self', ... }:
        let
          nixDependencies = lib.makeScope pkgs.newScope (
            import (inputs.nix + "/packaging/dependencies.nix") {
              inherit pkgs;
              inherit (pkgs) stdenv;
              inputs = { };
            }
          );
          nixComponents = lib.makeScope nixDependencies.newScope (
            import (inputs.nix + "/packaging/components.nix") {
              officialRelease = true;
              inherit lib pkgs;
              src = inputs.nix;
              maintainers = [ ];
            }
          );
          drvArgs = {
            srcDir = self;
            inherit nixComponents;
          };
        in
        {
          treefmt.imports = [ ./dev/treefmt.nix ];
          packages.nix-eval-jobs = pkgs.callPackage ./default.nix drvArgs;
          packages.clangStdenv-nix-eval-jobs = pkgs.callPackage ./default.nix (
            drvArgs // { stdenv = pkgs.clangStdenv; }
          );
          packages.default = self'.packages.nix-eval-jobs;
          devShells.default = pkgs.callPackage ./shell.nix drvArgs;
          devShells.clang = pkgs.callPackage ./shell.nix (drvArgs // { stdenv = pkgs.clangStdenv; });

          checks = builtins.removeAttrs self'.packages [ "default" ] // {
            shell = self'.devShells.default;
            clang-tidy-fix = self'.packages.nix-eval-jobs.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ [
                pkgs.git
                (lib.hiPrio pkgs.llvmPackages_latest.clang-tools)
              ];
              buildPhase = ''
                export HOME=$TMPDIR
                cat > $HOME/.gitconfig <<EOF
                [user]
                  name = Nix
                  email = nix@localhost
                [init]
                  defaultBranch = main
                EOF
                pushd ..
                git init
                git add .
                git commit -m init --quiet
                popd
                ninja clang-tidy-fix
                git status
                if ! git --no-pager diff --exit-code; then
                  echo "clang-tidy-fix failed, please run `ninja clang-tidy-fix` and commit the changes"
                  exit 1
                fi
              '';
              installPhase = ''
                touch $out
              '';
            });
          };
        };
    };
}
