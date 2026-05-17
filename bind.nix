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

in {
  # networking.firewall.allowedTCPPorts = [ 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
  services.bind = {
    enable = true;
    extraConfig = ''

      acl "slaves"  { ${lib.concatStringsSep "; " trustedSlaves}; };
      acl "masters" { ${lib.concatStringsSep "; " masterAcl};     };
    '';
   extraOptions = ''
    version "none";
    recursion no;
    max-udp-size 512;
    tcp-clients 50;
    tcp-idle-timeout 5000;    # 5 s in milliseconds
    deny-answer-addresses { any; } except-from { "${domain}"; };
      #    - "responses-per-second": hard cap on identical answers
      #    - "all-per-second": cap on ALL responses to one source (anti-flood)
      #    - "slip 2": every 2nd excess query gets a TRUNCATED answer,
      #      nudging legit clients to retry over TCP (amplification is UDP-only)
      #    - "window 5": rolling 5-second accounting window
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
          allow-transfer  { slaves; };
          allow-notify    { slaves; };
          notify          yes;
          also-notify     { ${kotekIp}; ${piesekIp}; };
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
