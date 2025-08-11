{pkgs, ip4, ...}: {
  
  
  networking.firewall.allowedTCPPorts = [ 80 443];
  services.caddy = {
    enable = true;

    virtualHosts = {
			"vaultwarden.sileanth.pl" = {
				extraConfig = ''
					reverse_proxy http://localhost:3012
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
