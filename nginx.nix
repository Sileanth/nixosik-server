{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  domain = "sileanth.pl";
  acmeEmail = "admin@${domain}";
  acmeEnvFile = "/var/lib/bind/acme-rfc2136.env";
  localNetworks = [
    "10.200.0.0/24"
    "127.0.0.1/32"
  ];
  localHosts = [
    "${hosts.kotek.private}/32"
    "${hosts.piesek.private}/32"
  ];

  mkVhost = extra: {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
  } // extra;

  mkPublicVhost = text: mkVhost {
    locations."/".extraConfig = ''
      default_type text/plain;
      return 200 "${text}\n";
    '';
  };

  mkPrivateVhost = text: mkVhost {
    listenAddresses = [
      hostInfo.private
      hostInfo.vpnIp
      "127.0.0.1"
    ];
    extraConfig = ''
      ${lib.concatMapStringsSep "\n" (network: "allow ${network};") (localNetworks ++ localHosts)}
      deny all;
    '';
    locations."/".extraConfig = ''
      default_type text/plain;
      return 200 "${text}\n";
    '';
  };

  mkPrivatePublicBlock = {
    serverName = "private.${domain}";
    listenAddresses = [ hostInfo.public ];
    onlySSL = true;
    sslCertificate = "/var/lib/acme/private.${domain}/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/private.${domain}/key.pem";
    locations."/".return = "403";
  };
in
{
  config = lib.mkIf (name == "main") {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = acmeEmail;
        dnsProvider = "rfc2136";
        environmentFile = acmeEnvFile;
        dnsPropagationCheck = false;
      };
    };

    systemd.services.nginx.after = [ "bind.service" ];

    services.caddy.enable = false;

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts = {
        "${domain}" = mkPublicVhost "sileanth.pl";
        "public.${domain}" = mkPublicVhost "public example";
        "kot.${domain}" = mkPublicVhost "public example";
        "private.${domain}" = mkPrivateVhost "private example";
        "private-public-block.${domain}" = mkPrivatePublicBlock;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
