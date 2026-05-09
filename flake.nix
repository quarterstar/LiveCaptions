{
  description = "LiveCaptions flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    april-asr-src = {
      url = "github:abb128/april-asr";
      flake = false;
    };

    april-asr-model = {
      url = "https://april.sapples.net/april-english-dev-01110_en.april";
      flake = false;
    };

  };
  outputs =
    {
      self,
      april-asr-src,
      april-asr-model,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          livecaptions = pkgs.stdenv.mkDerivation rec {
            src = ./.;
            name = "livecaptions";

            nativeBuildInputs = with pkgs; [
              meson
              ninja
              pkg-config
              cmake
              wrapGAppsHook3
              desktop-file-utils
              gettext
            ];

            buildInputs = with pkgs; [
              cmake
              appstream-glib # appstream-util
              desktop-file-utils # desktop-file-utils
              gettext # msgfmt
              glib # glib-compile-schemas
              libadwaita # libadwaita-1
              libpulseaudio # libpulse
              onnxruntime
            ];

            postPatch = ''
              mkdir -p subprojects/april-asr
              cp -r ${april-asr-src}/* subprojects/april-asr/
              chmod -R +w subprojects/april-asr
            '';

            postUnpack = ''
              mkdir -p source/subprojects/april-asr
              cp -r ${april-asr-src}/* source/subprojects/april-asr/
              chmod -R +w source/subprojects/april-asr
            '';

            preFixup = ''
              gappsWrapperArgs+=(--prefix APRIL_MODEL_PATH : "${april-asr-model}")
            '';

            meta = with pkgs.lib; {
              description = "Linux Desktop application that provides live captioning";
              homepage = "https://github.com/abb128/LiveCaptions";
              license = licenses.gpl3;
              platforms = platforms.linux;
            };
          };
          default = livecaptions;
        };
        apps = rec {
          livecaptions = flake-utils.lib.mkApp { drv = self.packages.${system}.livecaptions; };
          default = livecaptions;
        };
        devShells.default = pkgs.mkShell {
          inherit (self.packages.${system}.livecaptions) buildInputs nativeBuildInputs;
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.onnxruntime}/lib
            export APRIL_MODEL_PATH=${april-asr-model}
          '';
        };
      }
    );
}
