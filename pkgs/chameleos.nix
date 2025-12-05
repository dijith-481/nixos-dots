{ lib, fetchFromGitHub, rustPlatform, pkg-config, makeWrapper, wayland, libxkbcommon, vulkan-loader, libGL }:

rustPlatform.buildRustPackage rec {
  pname = "chameleos";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "Treeniks";
    repo = "chameleos";
    rev = "v${version}";
    hash = "sha256-zCAYEtDYJm9A+HC9M2XLtz47q+6dcBOVPgh4lmp4z/k="; # Replace after first run
  };

  cargoHash = "sha256-zBEu/T17W7dwz8jxnXm2NsHaVZo1wDFSW75yiYfRIoY="; # Replace after first run

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ wayland libxkbcommon ];

  postPatch = ''
    echo 'fn main() { println!("cargo:rustc-env=GIT_HASH=${version}"); }' > build.rs
  '';
  postInstall = ''
    wrapProgram $out/bin/chameleos \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader libGL ]}
  '';
}
