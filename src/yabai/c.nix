{ stdenv
, fetchFromGitHub
, Carbon
, Cocoa
, CoreServices
, IOKit
, ScriptingBridge
}:

stdenv.mkDerivation rec {
  pname = "yabai";
  version = "2.1.3";
  src = fetchFromGitHub {
    owner = "koekeishiya";
    repo = pname;
    rev = "v${version}";
    sha256 = "1g8ilbnr0vs4gn4a17jdrlhl3x3jrb5c43cgpwnzxc518dcyba2f";
  };

  buildInputs = [ Carbon Cocoa CoreServices IOKit ScriptingBridge ];

  installPhase = ''
    install -d $out/bin
    cp bin/yabai $out/bin
  '';

  meta = with stdenv.lib; {
    description = "A tiling window manager for macOS based on binary space partitioning";
    homepage = https://github.com/koekeishiya/yabai;
    platforms = platforms.darwin;
    license = licenses.mit;
  };
}
