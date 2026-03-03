{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, crane }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f { pkgs = import nixpkgs { inherit system; }; });
    in {
      packages = forAllSystems ({ pkgs }:
        let
          craneLib = crane.mkLib pkgs;
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              (craneLib.filterCargoSources path type) || (pkgs.lib.hasSuffix ".ttf" path);
          };
          commonArgs = {
            inherit src;
            pname = "osk";
            version = "0.1.0";
            nativeBuildInputs = [ pkgs.pkg-config pkgs.makeWrapper ];
            buildInputs = [ pkgs.libxkbcommon pkgs.wayland ];
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        in {
          default = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;

            postFixup = ''
              wrapProgram $out/bin/osk \
                --set OSK_FONT "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf" \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.wayland pkgs.libxkbcommon ]}
            '';

            meta = {
              description = "AZERTY on-screen keyboard for Wayland with auto-show on text input focus";
              platforms = pkgs.lib.platforms.linux;
              mainProgram = "osk";
            };
          });
        });
    };
}
