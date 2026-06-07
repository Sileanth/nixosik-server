{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  isMain = name == "main";



in
{
  services.navidrome = lib.mkIf isMain {
    enable = true;
    # settings.MusicFolder = "/mnt/audio/music";
  };
}
