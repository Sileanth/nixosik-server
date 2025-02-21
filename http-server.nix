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
                  return = "200 '${message}'";
                  extraConfig = ''
                    default_type text/html;
                  '';
              };
          };

        in {
          "sileanth.pl" = message-website ''
<!DOCTYPE html>
<html>
<head>
<title>Prask</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to prask!</h1>
<h2> Certificate</h2>
<img src="//ipv6.he.net/certification/create_badge.php?pass_name=sileanth&amp;badge=1" style="border: 0; width: 128px; height: 128px" alt="IPv6 Certification Badge for sileanth"></img>
<h2>Secret message:</h2>
<p>YWxhIG1hIGtvdGEKp>
</body>
</html>
          '' {
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
