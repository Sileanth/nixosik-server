{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  isPiesek = name == "piesek";
in
{
  services.calibre-server = lib.mkIf isPiesek {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    libraries = [ "/var/lib/calibre-server" ];
    openFirewall = false;
  };
}
