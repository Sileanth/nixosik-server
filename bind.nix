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
  services.bind = {
    enable = true;
    

    zones = lib.mkIf (isMaster || isSlave) {
      "${domain}" = if isMaster then {
        master = true;
        slaves = [ kotekIp piesekIp ];
        file = pkgs.writeText "${domain}.zone" ''
          ; ULTRA-FAST TEST SETUP
          $TTL 30      ; Default TTL (30 seconds)
          
          @       IN      SOA     ns0.${domain}. admin.${domain}. (
                          2026050301 ; serial
                          60         ; refresh (1 min)   - PROD: 7200 (2h)
                          30         ; retry (30 sec)    - PROD: 3600 (1h)
                          120        ; expire (2 mins)   - PROD: 1209600 (2w)
                          30         ; minimum (30 sec)  - PROD: 3600 (1h)
          )
          
          ; Name Servers
          @       IN      NS      ns0.${domain}.
          @       IN      NS      ns1.${domain}.
          @       IN      NS      ns2.${domain}.
          
          ; Glue Records / A Records for NS
          ns0     IN      A       ${mainIp}
          ns1     IN      A       ${kotekIp}
          ns2     IN      A       ${piesekIp}
          
          ; Main traffic records
          @       IN      A       ${mainIp}
          *       IN      A       ${mainIp}

          ; RECOMMENDED PROD SETTINGS:
          ; $TTL 86400 (1 day)
          ; Refresh: 7200 (2 hours)
          ; Retry: 3600 (1 hour)
          ; Expire: 1209600 (2 weeks)
          ; Negative Cache (Minimum): 3600 (1 hour)
        '';
      } else {
        master = false;
        masters = [ mainIp ];
        file = "/var/lib/bind/${domain}.zone";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
