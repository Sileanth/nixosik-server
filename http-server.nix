{pkgs, ...}: {

   networking.firewall.allowedTCPPorts = [ 80 443];


    security.acme.acceptTerms = true;
    security.acme.defaults.email = "lukasz.magnuszewski@gmail.com";



   services.nginx = {
       enable = true;
       virtualHosts."sileanth.eu" = {
        forceSSL = false;
        enableACME = true;
        locations."/" = {
            return = "200 '<html><body>It works3</body></html>'";
            extraConfig = ''
              default_type text/html;
            '';
        };
     };
   };
  }
