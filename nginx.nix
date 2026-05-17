{ config, lib, pkgs, name, hostInfo, hosts, ... }:

let
  domain = "sileanth.pl";
  acmeEmail = "admin@${domain}";
  acmeEnvFile = "/var/lib/bind/acme-rfc2136.env";
  localNetworks = [
    "10.0.0.0/24"
    "10.200.0.0/24"
    "127.0.0.1/32"
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
      ${lib.concatMapStringsSep "\n" (network: "allow ${network};") localNetworks}
      deny all;
    '';
    locations."/".extraConfig = ''
      default_type text/plain;
      return 200 "${text}\n";
    '';
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
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
