{
  stdenv,
  lib,
  nixComponents,
  pkgs,
  srcDir ? null,
}:

stdenv.mkDerivation {
  pname = "nix-eval-jobs";
  version = "2.29.0";
  src =
    if srcDir == null then
      lib.fileset.toSource {
        fileset = lib.fileset.unions [
          ./meson.build
          ./src/meson.build
          (lib.fileset.fileFilter (file: file.hasExt "cc") ./src)
          (lib.fileset.fileFilter (file: file.hasExt "hh") ./src)
        ];
        root = ./.;
      }
    else
      srcDir;
  buildInputs = with pkgs; [
    nlohmann_json
    curl
    nixComponents.nix-store
    nixComponents.nix-fetchers
    nixComponents.nix-expr
    nixComponents.nix-flake
    nixComponents.nix-main
    nixComponents.nix-cmd
  ];
  nativeBuildInputs =
    with pkgs;
    [
      meson
      pkg-config
      ninja
      # nlohmann_json can be only discovered via cmake files
      cmake
    ]
    ++ (lib.optional stdenv.cc.isClang [ pkgs.clang-tools ]);

  passthru = {
    inherit nixComponents;
  };

  meta = {
    description = "Hydra's builtin hydra-eval-jobs as a standalone";
    homepage = "https://github.com/nix-community/nix-eval-jobs";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [
      adisbladis
      mic92
    ];
    platforms = lib.platforms.unix;
  };
}
