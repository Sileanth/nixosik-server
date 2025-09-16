{pkgs, ip4, ...}: {
  
  
  networking.firewall.allowedTCPPorts = [ 80 443];
  services.caddy = {
    enable = true;

    virtualHosts = {
			"git.sileanth.pl" = {
				extraConfig = ''
					reverse_proxy http://localhost:3011
				'';
			};
			"vaultwarden.sileanth.pl" = {
				extraConfig = ''
					reverse_proxy http://localhost:3012
				'';
			};
			"calibre.sileanth.pl" = {
				extraConfig = ''
					reverse_proxy http://localhost:3013
				'';
			};
      "couchdb.sileanth.pl" = {
        extraConfig = ''
          reverse_proxy http://localhost:5984
        '';
      };
      "sileanth.pl" = {
        extraConfig = ''
          respond "Hello, world!"
        '';
      };
    };
  };


}
