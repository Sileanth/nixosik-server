{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  isHub = name == "main";
  
  # Filter out the current host from the peers list
  peerHosts = lib.filterAttrs (n: v: n != name) hosts;
  
  # Helper to create a peer config
  mkPeer = peerName: peerInfo: {
    PublicKey = peerInfo.wgPubKey;
    AllowedIPs = [ "${peerInfo.vpnIp}/32" ];
  } // lib.optionalAttrs (!isHub && peerName == "main") {
    # If this is not the hub, and the peer is the hub, add endpoint and keepalive
    Endpoint = "${peerInfo.public}:51820";
    PersistentKeepalive = 25;
  };

in
{
  systemd.network.netdevs."50-wg0" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg0";
      Description = "WireGuard VPN";
    };
    wireguardConfig = {
      ListenPort = if isHub then 51820 else null;
      PrivateKeyFile = "/etc/wireguard/private.key";
    };
    # Hub connects to everyone; Nodes only connect to Hub
    wireguardPeers = if isHub 
      then lib.mapAttrsToList mkPeer peerHosts
      else [ (mkPeer "main" hosts.main) ];
  };

  systemd.network.networks."50-wg0" = {
    matchConfig.Name = "wg0";
    address = [ "${hostInfo.vpnIp}/24" ];
    networkConfig.IPForward = "yes";
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
}
