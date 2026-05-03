{ config, lib, pkgs, hostInfo, name, ... }:

{
  networking.useDHCP = false;
  networking.useNetworkd = true;

  networking.hostName = name;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = hostInfo.interface;
    networkConfig.Address = [ "${hostInfo.private}/24" ];
    networkConfig.Gateway = "10.0.0.1";
    networkConfig.DNS = [ "169.254.169.254" ];
  };
}
