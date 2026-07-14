{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);

      firmwareArgs = {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [
          ".board"
          ".cmake"
          ".conf"
          ".defconfig"
          ".dts"
          ".dtsi"
          ".json"
          ".keymap"
          ".overlay"
          ".shield"
          ".yml"
          "_defconfig"
        ];

        board = "nice_nano";
        shield = "sofle_%PART%";

        zephyrDepsHash = "sha256-Yom35sq0qg8zJX41PBrsnS2zgz51ywZ9To3yT7aLG/M=";

        snippets = [
          "nrf52840-nosd"
        ];

        config = "./config";

        enableZmkStudio = true;

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

    in
    {
      packages = forAllSystems (system: rec {
        default = firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard firmwareArgs;

        settings_reset = zmk-nix.legacyPackages.${system}.buildSplitKeyboard (
          firmwareArgs
          // {
            enableZmkStudio = false;
            name = "settings_reset";
            shield = "settings_reset";
            parts = [
              "reset"
            ];
          }
        );

        flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
