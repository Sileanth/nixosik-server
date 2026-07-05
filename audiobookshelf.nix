{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  isPiesek = name == "piesek";
in
{
  services.audiobookshelf = lib.mkIf isPiesek {
    enable = true;
  };
}
