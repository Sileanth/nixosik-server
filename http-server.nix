{pkgs, ...}: {

   networking.firewall.allowedTCPPorts = [ 80 443];


    # lets encrypt ssl provider
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "lukasz.magnuszewski@gmail.com";



   services.nginx = {
       enable = true;
       virtualHosts = let
        common = {

          forceSSL = true;
          enableACME = true;
          };
        message-website =  message : extra : extra // common // {
              locations."/" = {
                  return = "200 '<html><body>${message}</body></html>'";
                  extraConfig = ''
                    default_type text/html;
                  '';
              };
          };

        in {
          "blog.sileanth.eu" = message-website "blog" {};
          "sklep.sileanth.eu" = message-website "sklep" {};
          "tetris.sileanth.eu" = message-website "tetris" {};
          "sileanth.eu" = message-website "main" {};
          "sileanth.pl" = message-website "pl" {};
        };
     };
  }
