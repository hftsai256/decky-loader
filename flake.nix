{
  description = "Decky development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = lib.intersectLists lib.systems.flakeExposed lib.platforms.linux;
      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});

      decky-loader-package =
        { lib
        , nodejs
        , pnpm
        , python3
        , coreutils
        , psmisc
        , systemd
        }:

        python3.pkgs.buildPythonPackage rec {
          pname = "decky-loader";
          version = "3.2.0";

          src = ./.;

          pnpmDeps = pnpm.fetchDeps {
            fetcherVersion = 1;
            inherit pname version src;
            sourceRoot = ./frontend;
            hash = "sha256-WJCyYi7ldPdMY0S+5cbrbGSXztLwmMWa2qLHDgra+dA=";
          };

          pnpmRoot = "frontend";

          nativeBuildInputs = [
            python3.pkgs.poetry-core
            python3.pkgs.poetry-dynamic-versioning
            nodejs
            pnpm.configHook
          ];

          pyproject = true;

          preBuild = ''
            cd frontend
            pnpm build
            cd ../backend
          '';

          dependencies = with python3.pkgs; [
            aiohttp
            aiohttp-jinja2
            aiohttp-cors
            hatchling
            watchdog
            certifi
            packaging
            multidict
            setproctitle
          ];

          makeWrapperArgs = [
            "--prefix PATH : ${lib.makeBinPath [ coreutils psmisc systemd ]}"
          ];

          passthru.python = python3;

          meta = with lib; {
            description = "A plugin loader for the Steam Deck";
            homepage = "https://github.com/SteamDeckHomebrew/decky-loader";
            platforms = platforms.linux;
            license = licenses.gpl2Only;
          };
        };


    in {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};

        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              python313
              python3.pkgs.poetry-core
              python3.pkgs.poetry-dynamic-versioning

              nodejs
              pnpm
              husky
            ];
          };
        });

      packages = forAllSystems (
        system:
        let
          decky-loader = nixpkgsFor.${system}.callPackage decky-loader-package {};

        in {
          inherit decky-loader;
          default = decky-loader;
        });

      overlay = final: _: {
        decky-loader = final.callPackage decky-loader-package {};
      };
    };
}
