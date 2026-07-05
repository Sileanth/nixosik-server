{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  isKotek = name == "kotek";
in
{
  services.navidrome = lib.mkIf isKotek {
    enable = true;
    # settings.MusicFolder = "/mnt/audio/music";
    settings = {
      MusicFolder = "/var/lib/navidrome";
    };
  };
}
