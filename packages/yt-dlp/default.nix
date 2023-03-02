{ unstable, ... }:
let
  inherit (import ./_version.nix) version rev sha256;
  inherit (unstable) lib python3Packages fetchFromGitHub;
in python3Packages.buildPythonPackage {
  pname = "yt-dlp";
  inherit version;

  src = fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    inherit rev sha256;
  };

  propagatedBuildInputs = with python3Packages; [
    brotli certifi mutagen pycryptodomex websockets
  ];

  # Ensure these utilities are available in $PATH:
  # - ffmpeg: post-processing & transcoding support
  # - rtmpdump: download files over RTMP
  # - atomicparsley: embedding thumbnails
  makeWrapperArgs =
    let
      packagesToBinPath = with unstable; [atomicparsley ffmpeg rtmpdump];
    in [
      ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"''
    ];

  setupPyBuildFlags = [
    "build_lazy_extractors"
  ];

  # Requires network
  doCheck = false;

  inherit (unstable.yt-dlp) meta;
}
