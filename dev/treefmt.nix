{ pkgs, lib, ... }:
let
  supportsDeno =
    lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.deno
    && (builtins.tryEval pkgs.deno.outPath).success;
in
{
  flakeCheck = pkgs.hostPlatform.system != "riscv64-linux";
  # Used to find the project root
  projectRootFile = "flake.lock";

  programs = {
    deno.enable = supportsDeno;
    yamlfmt.enable = true;

    clang-format = {
      enable = true;
      package = pkgs.llvmPackages_latest.clang-tools;
    };

    deadnix.enable = true;
    nixfmt.enable = true;
    mypy = {
      enable = true;
      directories = {
        "tests" = {
          extraPythonPackages = [ pkgs.python3Packages.pytest ];
        };
      };
    };
    ruff.format = true;
    ruff.check = true;
  };}
