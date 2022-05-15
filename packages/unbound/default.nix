{ pkgs

# Avoid .lib depending on lib.getLib openssl
# The build gets a little hacky, so in some cases we disable this approach.
, withSlimLib ? pkgs.stdenv.isLinux && !pkgs.stdenv.hostPlatform.isMusl

, ...
}:
let
  inherit (import ./_version.nix) version sha256;
in
pkgs.stdenv.mkDerivation rec {
  pname = "unbound";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz";
    inherit sha256;
  };

#  outputs = [ "out" "lib" "man" ]; # "dev" would only split ~20 kB

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildInputs = [
    pkgs.openssl
    pkgs.nettle
    pkgs.expat
    pkgs.libevent
    pkgs.pkg-config
    pkgs.systemd
    pkgs.libnghttp2
  ];

  configureFlags = [
    "--with-ssl=${pkgs.openssl.dev}"
    "--with-libexpat=${pkgs.expat.dev}"
    "--with-libevent=${pkgs.libevent.dev}"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--sbindir=\${out}/bin"
    "--with-rootkey-file=${pkgs.dns-root-data}/root.key"
    "--enable-pie"
    "--enable-relro-now"
  ] ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isStatic [
    "--disable-flto"
  ] ++ [
    "--enable-systemd"
    "--with-libnghttp2=${pkgs.libnghttp2.dev}"
    "--disable-subnet"
    "--disable-dnscrypt"
    "--disable-dnstap"
    "--disable-tfo-client"
    "--disable-tfo-server"
  ] ++ [
    "--disable-cachedb"
  ];

  # Remove references to compile-time dependencies that are included in the configure flags
  postConfigure = let
    inherit (builtins) storeDir;
  in ''
    sed -E '/CONFCMDLINE/ s;${storeDir}/[a-z0-9]{32}-;${storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-;g' -i config.h
  '';

  checkInputs = [ pkgs.bison ];

  doCheck = true;

  installFlags = [ "configfile=\${out}/etc/unbound/unbound.conf" ];

  postInstall = ''
    make unbound-event-install
    wrapProgram $out/bin/unbound-control-setup \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.openssl ]}
  '';

  preFixup = pkgs.lib.optionalString withSlimLib
    # Build libunbound again, but only against nettle instead of openssl.
    # This avoids gnutls.out -> unbound.lib -> lib.getLib openssl.
    ''
      configureFlags="$configureFlags --with-nettle=${pkgs.nettle.dev} --with-libunbound-only"
      configurePhase
      buildPhase
      if [ -n "$doCheck" ]; then
          checkPhase
      fi
      installPhase
    ''
  # get rid of runtime dependencies on $dev outputs
  + ''substituteInPlace "$lib/lib/libunbound.la" ''
  + pkgs.lib.concatMapStrings
    (pkg: pkgs.lib.optionalString (pkg ? dev) " --replace '-L${pkg.dev}/lib' '-L${pkg.out}/lib' --replace '-R${pkg.dev}/lib' '-R${pkg.out}/lib'")
    (builtins.filter (p: p != null) buildInputs);

  passthru.tests = pkgs.nixosTests.unbound;

  enableParallelBuilding = true;

  meta = {
    inherit (pkgs.unbound.meta) description homepage license;
    platforms = with pkgs.lib.platforms; linux;
  };
}
