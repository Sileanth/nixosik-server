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
  environment.systemPackages = [ pkgs.wireguard-tools ];

  systemd.tmpfiles.rules = [
    "d /etc/wireguard 0750 root systemd-network - -"
    "z /etc/wireguard/private.key 0640 root systemd-network - -"
  ];

  systemd.network.netdevs."50-wg0" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg0";
      Description = "WireGuard VPN";
    };
    wireguardConfig = {
      PrivateKeyFile = "/etc/wireguard/private.key";
      RouteTable = "main";
    } // lib.optionalAttrs isHub {
      ListenPort = 51820;
    };
    # Hub connects to everyone; Nodes only connect to Hub
    wireguardPeers = if isHub
      then lib.mapAttrsToList mkPeer peerHosts
      else [ (mkPeer "main" hosts.main) ];
  };

  systemd.network.networks."50-wg0" = {
    matchConfig.Name = "wg0";
    address = [ "${hostInfo.vpnIp}/24" ];
    networkConfig = lib.mkIf isHub {
      DHCP = "no";
      LinkLocalAddressing = "no";
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };
  };

  networking.nat = lib.mkIf isHub {
    enable = true;
    enableIPv6 = true;
    externalInterface = hostInfo.interface;
    internalInterfaces = [ "wg0" ];
  };

  networking.firewall.allowedUDPPorts = lib.mkIf isHub [ 51820 ];
}
