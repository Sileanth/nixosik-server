{pkgs, ...}: {

   networking.firewall.allowedTCPPorts = [ 80 443];


    # lets encrypt ssl provider
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "lukasz.magnuszewski@gmail.com";



   services.nginx = {
       enable = true;


        # experimental quic support
        package = pkgs.nginxQuic;


        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        appendHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            # Adding this header to HTTP requests is discouraged
            map $scheme $hsts_header {
              https   "max-age=31536000; includeSubdomains; preload";
            }
            add_header Strict-Transport-Security $hsts_header;



              add_header Content-Security-Policy "default-src 'self'; img-src * data:; style-src 'self' 'unsafe-inline'";
              add_header X-XSS-Protection "0";
#add_header X-XSS-Protection "1; mode=block"; # can potentaily be unsafe, attacker can disable some parts of js
              add_header X-Frame-Options "SAMEORIGIN";
              add_header X-Content-Type-Options nosniff;
              add_header Referrer-Policy "strict-origin";
              add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()";



            '';

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
          # "blog.sileanth.eu" = message-website "blog" {};
          # "sklep.sileanth.eu" = message-website "sklep" {};
          # "tetris.sileanth.eu" = message-website "tetris" {};
          # "sileanth.eu" = message-website "main" {};
          "sileanth.pl" = message-website "pl" {
            serverAliases = [
              "www.sileanth.pl"
            ];

            # experimental http3, quic
            quic = true;
            http3 = true;



          };
        };
     };
  }
