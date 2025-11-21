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

  src = ../../.;

  pnpmDeps = pnpm.fetchDeps {
    fetcherVersion = 1;
    inherit pname version src;
    sourceRoot = ../../frontend;
    hash = "sha256-WJCyYi7ldPdMY0S+5cbrbGSXztLwmMWa2qLHDgra+dA=";
  };

  pnpmRoot = "frontend";

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pyproject = true;
  build-system = [ python3.pkgs.setuptools ];

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
}
