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

        in {
          "blog.sileanth.eu" = common // {
              locations."/" = {
                  return = "200 '<html><body>Blog</body></html>'";
                  extraConfig = ''
                    default_type text/html;
                  '';
              };
          };
 
          "sileanth.eu" = common // {
              locations."/" = {
                  return = "200 '<html><body>It works3</body></html>'";
                  extraConfig = ''
                    default_type text/html;
                  '';
              };
          };
     };
   };
  }
