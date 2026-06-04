{ config, lib, pkgs, name, hosts, ... }:

let
  domain = "sileanth.pl";
  acmeEmail = "admin@${domain}";
  acmeEnvFile = "/var/lib/bind/acme-rfc2136.env";
  localNetworks = [
    "10.0.0.0/24"
    "10.200.0.0/24"
    "127.0.0.1/32"
  ];

  commonVhost = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
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
        "${domain}" = commonVhost // {
          locations."/".extraConfig = ''
            default_type text/plain;
            return 200 "sileanth.pl\n";
          '';
        };

        "public.${domain}" = commonVhost // {
          locations."/".extraConfig = ''
            default_type text/plain;
            return 200 "public example\n";
          '';
        };

        "kot.${domain}" = commonVhost // {
          locations."/".extraConfig = ''
            allow 127.0.0.1;
            allow 10.200.0.0/24;
            allow ::1;
            deny all;
            default_type text/plain;
            return 200 "public example\n";
          '';
        };

        "private.${domain}" = commonVhost // {
            # ${lib.concatMapStringsSep "\n" (network: "allow ${network};") localNetworks}
          extraConfig = ''
            deny all;
            default_type text/plain;
            return 200 "private example\n";
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
