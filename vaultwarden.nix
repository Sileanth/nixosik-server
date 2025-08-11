{pkgs, ip4, ...}: {
  
  

  services.vaultwarden = {
    enable = true;
		dbBackend = "sqlite";
		config = {
			DOMAIN = "https://vaultwarden.sileanth.pl";
		  ROCKET_ADDRESS = "127.0.0.1";
			ROCKET_PORT = 3012;
			ROCKET_LOG = "critical";
			SIGNUPS_ALLOWED = false;
		};
		environmentFile = "/secrets/vaultwarden.env";





  };


}
