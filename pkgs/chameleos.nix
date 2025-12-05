{ lib, fetchFromGitHub, rustPlatform, pkg-config, makeWrapper, wayland, libxkbcommon, vulkan-loader, libGL }:

rustPlatform.buildRustPackage rec {
  pname = "chameleos";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "Treeniks";
    repo = "chameleos";
    rev = "v${version}";
    hash = lib.fakeHash; # Replace after first run
  };

  cargoHash = lib.fakeHash; # Replace after first run

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ wayland libxkbcommon ];

  postInstall = ''
    wrapProgram $out/bin/chameleos \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader libGL ]}
  '';
}
