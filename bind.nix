{ config, lib, pkgs, name, ... }:

let
  hosts = import ./hosts.nix;
  domain = "sileanth.pl";
  privateDomain = "private.${domain}";
  
  mainIp    = hosts.main.public;
  mainVpnIp = hosts.main.vpnIp;
  kotekIp   = hosts.kotek.public;
  kotekVpnIp = hosts.kotek.vpnIp;
  piesekIp  = hosts.piesek.public;
  acmeKeyName = "rfc2136key.${domain}.";

  isMaster = name == "main";
  isSlave  = name == "kotek" || name == "piesek";
  trustedSlaves = [ "${kotekIp}/32" "${piesekIp}/32" ];
  masterAcl     = [ "${mainIp}/32" ];
  aclEntries = entries: lib.concatStringsSep " " (map (entry: "${entry};") entries);

  serial = "2025010105";

  mainZone = pkgs.writeText "${domain}.zone" ''
    $TTL 30      ; Default TTL (30 seconds)

    @       IN      SOA     ns0.${domain}. admin.${domain}. (
                            ${serial}  ; serial
                            60         ; refresh
                            30         ; retry
                            120        ; expire
                            30         ; minimum
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


    navidrome       IN      A       ${kotekVpnIp}
    audiobookshelf  IN      A       ${hosts.piesek.vpnIp}
    grafana       IN      A       ${mainVpnIp}
  '';

  privateZone = pkgs.writeText "${privateDomain}.zone" ''
    $TTL 30      ; Default TTL (30 seconds)

    @       IN      SOA     ns0.${domain}. admin.${domain}. (
                            ${serial}  ; serial
                            60         ; refresh
                            30         ; retry
                            120        ; expire
                            30         ; minimum
    )

    ; Name Servers
    @       IN      NS      ns0.${domain}.
    @       IN      NS      ns1.${domain}.
    @       IN      NS      ns2.${domain}.

    ; Private traffic records
    @       IN      A       ${mainVpnIp}
    @       IN      A       ${mainVpnIp}
  '';

in {
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  systemd.services.bind.serviceConfig.StateDirectory = "bind";

  services.bind = {
    enable = true;
    checkConfig = !isMaster;
    cacheNetworks = [];
    extraConfig = ''
      acl "slaves"  { ${aclEntries trustedSlaves} };
      acl "masters" { ${aclEntries masterAcl} };
    '' + lib.optionalString isMaster ''

      include "/var/lib/bind/dnskeys.conf";
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
          allow-update { key ${acmeKeyName}; };
          notify yes;
          also-notify { ${aclEntries [ kotekIp piesekIp ]} };
        '';
        file = "${mainZone}";
      } else {
        master = false;
        masters = [ mainIp ];
        file = "/var/lib/bind/${domain}.zone";
        extraConfig = ''
          allow-transfer  { none; };
          allow-notify    { masters; };
        '';
      };

      "${privateDomain}" = if isMaster then {
        master = true;
        slaves = [ kotekIp piesekIp ];
        extraConfig = ''
          allow-update { key ${acmeKeyName}; };
          notify yes;
          also-notify { ${aclEntries [ kotekIp piesekIp ]} };
        '';
        file = "${privateZone}";
      } else {
        master = false;
        masters = [ mainIp ];
        file = "/var/lib/bind/${privateDomain}.zone";
        extraConfig = ''
          allow-transfer  { none; };
          allow-notify    { masters; };
        '';
      };
    };
  };

  systemd.services.bind-rfc2136-conf = lib.mkIf isMaster {
    requiredBy = [ "bind.service" ];
    before = [ "bind.service" ];
    unitConfig.ConditionPathExists = "!/var/lib/bind/dnskeys.conf";
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    path = [ pkgs.bind pkgs.gnused ];
    script = ''
      tsig-keygen -a hmac-sha256 ${acmeKeyName} > /var/lib/bind/dnskeys.conf
      chown named:named /var/lib/bind/dnskeys.conf
      chmod 0400 /var/lib/bind/dnskeys.conf

      secret="$(
        sed -n 's/^[[:space:]]*secret[[:space:]]*"\(.*\)";/\1/p' /var/lib/bind/dnskeys.conf
      )"

      {
        printf '%s\n' "RFC2136_NAMESERVER='127.0.0.1:53'"
        printf '%s\n' "RFC2136_TSIG_ALGORITHM='hmac-sha256.'"
        printf '%s\n' "RFC2136_TSIG_KEY='${acmeKeyName}'"
        printf '%s\n' "RFC2136_TSIG_SECRET='$secret'"
      } > /var/lib/bind/acme-rfc2136.env
      chown root:root /var/lib/bind/acme-rfc2136.env
      chmod 0400 /var/lib/bind/acme-rfc2136.env
    '';
  };
}
