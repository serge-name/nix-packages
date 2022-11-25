{ stable, ... }:
let
  inherit (import ./_version.nix) version sha256;
  inherit (stable) stdenv lib fetchurl pkg-config squid;
in
stdenv.mkDerivation rec {
  pname = "squid";
  inherit version;

  src = fetchurl {
    url = "http://www.squid-cache.org/Versions/v${lib.versions.major version}/${pname}-${version}.tar.xz";
    inherit sha256;
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = with stable; [
    perl db openssl libcap file
    # pam expat libxml2 cyrus_sasl openldap
  ];

  configureFlags = [
    "--disable-ipv6" # "--enable-ipv6"
    "--disable-auto-locale"
#    "--disable-strict-error-checking"
    "--disable-arch-native"
    "--disable-wccp"
    "--disable-wccpv2"
    "--disable-snmp"
    "--enable-cachemgr-hostname=localhost"
    "--disable-ident-lookups"
    "--disable-auth"
    "--with-openssl"
    "--enable-ssl-crtd"
    "--enable-storeio=ufs,aufs,diskd,rock"
    "--enable-removal-policies=lru,heap"
    "--enable-delay-pools"
    "--disable-esi"
    "--disable-htcp"
#    "--enable-x-accelerator-vary"
    "--enable-linux-netfilter"
  ];

  postInstall = ''
    mv $out/bin/purge $out/bin/squidpurge
    mv $out/share/man/man1/purge.1 $out/share/man/man1/squidpurge.1
    rm -rf $out/var
  '';

  patches = [
    patches/bind_interface_outgoing.patch
    patches/env_vars_macro.patch
    patches/fix_dirs.patch
    patches/service_name.patch
  ];

  enableParallelBuilding = true;

  meta = {
    inherit (squid.meta) description homepage license;
    platforms = with lib.platforms; linux;
  };
}
