{ config, lib, pkgs, name, hosts, ... }:

let
  domain = "sileanth.pl";
  acmeEmail = "admin@${domain}";
  acmeEnvFile = "/var/lib/bind/acme-rfc2136.env";
  isMain = name == "main";
  isKotek = name == "kotek";
  isPiesek = name == "piesek";
  enableNginx = isMain || isKotek || isPiesek;
  localNetworks = [
    "10.0.0.0/24"
    "10.200.0.0/24"
    "127.0.0.1/32"
    "::1/128"
  ];
  allowLocalNetworks = lib.concatMapStringsSep "\n" (network: "allow ${network};") localNetworks;

  commonVhost = {
    enableACME = true;
    forceSSL = true;
    acmeRoot = null;
  };

  navidromeVhost = {
    "navidrome.${domain}" = commonVhost // {
      locations."/" = {
        extraConfig = ''
          ${allowLocalNetworks}
          deny all;
        '';
        proxyPass = "http://127.0.0.1:4533";
      };
    };
  };

  audiobookshelfVhost = {
    "audiobookshelf.${domain}" = commonVhost // {
      locations."/" = {
        extraConfig = ''
          ${allowLocalNetworks}
          client_max_body_size 0;
          deny all;
        '';
        proxyPass = "http://127.0.0.1:8000";
        proxyWebsockets = true;
      };
    };
  };

  mainVhosts = {
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
      locations."/" = {
        extraConfig = ''
          ${allowLocalNetworks}
          deny all;
        '';
        root = pkgs.writeTextDir "index.html" "private example";
      };
    };

    "grafana.${domain}" = commonVhost // {
      locations."/" = {
        extraConfig = ''
          ${allowLocalNetworks}
          deny all;
        '';
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
in
{
  config = lib.mkIf enableNginx {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = acmeEmail;
      } // lib.optionalAttrs (isMain || isKotek || isPiesek) {
        dnsProvider = "rfc2136";
        environmentFile = acmeEnvFile;
        dnsPropagationCheck = false;
      };
    };

    systemd.services.nginx.after = lib.mkIf isMain [ "bind.service" ];

    services.caddy.enable = false;

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts =
        lib.optionalAttrs isMain mainVhosts
        // lib.optionalAttrs isKotek navidromeVhost
        // lib.optionalAttrs isPiesek audiobookshelfVhost;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
