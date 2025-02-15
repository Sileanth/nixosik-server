{pkgs, vars, ...}: 
let
      	main = vars.ip4;
	main6 = vars.ip6;
	ns = "158.101.202.37";
  ns6 = "2603:c022:c007:147e:3e52:9996:45b5:2127#53(2603:c022:c007:147e:3e52:9996:45b5:2127";
in {


  # systemd.tmpfiles.rules = [
  #   "d /dynamic/bind/keys 0770 bind bind - -"
  # ];
    system.activationScripts.bind-zones.text = ''
    mkdir -p /etc/bind/keys
    mkdir -p /etc/bind/zones
    chown named:named /etc/bind/keys
    chown named:named /etc/bind/zones
  '';

 # this files need to be outside nix store, bcs signed file is based on this
 # bind is leading whitespace significant
 # if in logs there is "no owner" error, then try to format section below
 environment.etc."bind/zones/sileanth.pl.zone" = {
    enable = true;
    user = "named";
    group = "named";
    mode = "0644";
    text = ''
$ORIGIN sileanth.pl.
$TTL 3600
@       IN      SOA      ns1.sileanth.pl. admin.sileanth.pl. (
56 ; Serial
600            ; Refresh
120           ; Retry
3600            ; Expire
3600 ) ; Negative Cache TTL
;

; Name servers
sileanth.pl.  IN  NS  ns1.sileanth.pl.
sileanth.pl.  IN  NS  ns2.sileanth.pl.


ns1 IN  A ${main}
ns2 IN  A ${ns}
ns1 IN  AAAA ${main6}
ns2 IN  AAAA ${ns6}



@ IN  A ${main}
@ IN  AAAA ${main6}


www IN  A ${main}
www IN  AAAA ${main6}
'';
  };
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts= [ 53 ];
  services.bind = {
    enable = true;
    zones = {
	"sileanth.tech" = {
		master = false; #  equivalent to slave
		masters = [ "91.204.161.22" ];
		file = "/etc/bind/zones/sileanth.tech.zone"; # Store outside /nix/store
	};
      "sileanth.eu" = {
        master = true;
        file = pkgs.writeText "sileanth.eu" ''
          $ORIGIN sileanth.eu.
          $TTL 3600
          @       IN      SOA      ns1.sileanth.eu. admin.sileanth.eu. (
            40 ; Serial
            600            ; Refresh
            120           ; Retry
            3600            ; Expire
            3600 ) ; Negative Cache TTL
          ;

          ; Name servers
          sileanth.eu.  IN  NS  ns1.sileanth.eu.
          sileanth.eu.  IN  NS  ns2.sileanth.eu.


          ns1 IN  A 135.181.87.151
          ns2 IN  A 135.181.87.151 ; to change



          @ IN  A 135.181.87.151
          tetris IN  A 135.181.87.151
          blog IN  A 135.181.87.151
          sklep IN  A 135.181.87.151



        '';
      };

      "sileanth.pl" = {
        master = true;
	slaves = [ ns ];
	extraConfig = ''
		inline-signing yes;
		dnssec-policy default;
		key-directory "/etc/bind/keys";  
	''; # dnssec setup, to get data for dnssec registar record run:

        file = "/etc/bind/zones/sileanth.pl.zone";


      };
    };
    cacheNetworks = [
      "127.0.0.0/24"
      "::1/128"
    ]; # which networks are allowed to recursive query
    # extraOptions = ''
    #   recursion no;
    # '';
  };

}
