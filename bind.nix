{ config, lib, pkgs, name, ... }:

let
  hosts = import ./hosts.nix;
  domain = "sileanth.pl";

  mainIp   = hosts.main.public;
  kotekIp  = hosts.kotek.public;
  piesekIp = hosts.piesek.public;

  isMaster = name == "main";
  isSlave  = name == "kotek" || name == "piesek";

in {

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];


  services.bind = {
    enable = true;

    extraOptions = ''
      recursion no;
      allow-query { any; };

      version "Not Disclosed";
      server-id none;

      rate-limit {
        responses-per-second 10;
        errors-per-second 5;
        window 5;
        log-only no;
      };

      deny-answer-aliases { any; };
    '';

    zones = lib.mkIf (isMaster || isSlave) {
      "${domain}" = if isMaster then {
        master = true;
        slaves = [ kotekIp piesekIp ];

        allowTransfer = [ kotekIp piesekIp ];

        extraConfig = ''
          also-notify { ${kotekIp}; ${piesekIp}; };
          notify yes;
        '';

        file = pkgs.writeText "${domain}.zone" ''
          $TTL 3600    ; 1 Hour default caching limit

          @       IN      SOA     ns0.${domain}. admin.${domain}. (
                          2026051801 ; Serial (YYYYMMDDNN style updated for May 2026)
                          60         ; refresh (1 min)   - PROD: 7200 (2h)
                          30         ; retry (30 sec)    - PROD: 3600 (1h)
                          120        ; expire (2 mins)   - PROD: 1209600 (2w)
                          30         ; minimum (30 sec)  - PROD: 3600 (1h)
          )

          @       IN      NS      ns0.${domain}.
          @       IN      NS      ns1.${domain}.
          @       IN      NS      ns2.${domain}.

          ns0     IN      A       ${mainIp}
          ns1     IN      A       ${kotekIp}
          ns2     IN      A       ${piesekIp}

          @       IN      A       ${mainIp}
          *       IN      A       ${mainIp}
        '';
      } else {
        master = false;
        masters = [ mainIp ];

        allowTransfer = [ "none" ];

        file = "/var/lib/bind/db.${domain}";
      };
    };
  };


}
