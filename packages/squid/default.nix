{ pkgs, }:
let
  inherit (import ./_version.nix) version sha256;
in
pkgs.stdenv.mkDerivation rec {
  pname = "squid";
  inherit version;

  src = pkgs.fetchurl {
    url = "http://www.squid-cache.org/Versions/v${pkgs.lib.versions.major version}/${pname}-${version}.tar.xz";
    inherit sha256;
  };

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [
    pkgs.perl pkgs.db pkgs.openssl pkgs.libcap pkgs.file
  ]; # pkgs.pam pkgs.expat pkgs.libxml2 pkgs.cyrus_sasl pkgs.openldap

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
    inherit (pkgs.squid.meta) description homepage license;
    platforms = with pkgs.lib.platforms; linux;
  };
}
