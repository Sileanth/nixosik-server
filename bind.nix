{ config, lib, pkgs, name, ... }:

let
  hosts = import ./hosts.nix;
  domain = "sileanth.pl";
  
  mainIp   = hosts.main.public;
  kotekIp  = hosts.kotek.public;
  piesekIp = hosts.piesek.public;

  isMaster = name == "main";
  isSlave  = name == "kotek" || name == "piesek";
  trustedSlaves = [ "${kotekIp}/32" "${piesekIp}/32" ];
  masterAcl     = [ "${mainIp}/32" ];
  aclEntries = entries: lib.concatStringsSep " " (map (entry: "${entry};") entries);

in {
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  systemd.services.bind.serviceConfig.StateDirectory = "bind";

  services.bind = {
    enable = true;
    cacheNetworks = [];
    extraConfig = ''

      acl "slaves"  { ${aclEntries trustedSlaves} };
      acl "masters" { ${aclEntries masterAcl} };
    '';
    extraOptions = ''
      version "none";

      recursion no;
      allow-recursion { none; };
      allow-query-cache-on { none; };
      minimal-responses yes;

      max-cache-ttl 30;
      max-ncache-ttl 30;
      max-cache-size 16M;

      max-udp-size 512;
      tcp-clients 50;
      tcp-idle-timeout 5;

      rate-limit {
        responses-per-second 5;
        referrals-per-second  2;
        nodata-per-second     5;
        errors-per-second     5;
        all-per-second       20;
        slip                  2;
        window                5;
        log-only             no;
      };
    '';

    zones = lib.mkIf (isMaster || isSlave) {
      "${domain}" = if isMaster then {
        master = true;
        slaves = [ kotekIp piesekIp ];
        extraConfig = ''
          allow-update   { none; };
          notify yes;
          also-notify { ${aclEntries [ kotekIp piesekIp ]} };
        '';
        file = pkgs.writeText "${domain}.zone" ''
          $TTL 30      ; Default TTL (30 seconds)
          
          @       IN      SOA     ns0.${domain}. admin.${domain}. (
                          2026050302 ; serial
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

        '';
      } else {
        master = false;
        masters = [ mainIp ];
        file = "/var/lib/bind/${domain}.zone";
        extraConfig = ''
          allow-transfer  { none; };
          allow-notify    { masters; };
        '';
      };
    };
  };
}
