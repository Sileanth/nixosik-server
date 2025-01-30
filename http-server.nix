{pkgs, ...}: {

   networking.firewall.allowedTCPPorts = [ 80 443];


   services.nginx = {
       enable = true;
       virtualHosts."sileanth.eu" = {
locations."/" = {
      return = "200 '<html><body>It works2</body></html>'";
      extraConfig = ''
        default_type text/html;
      '';
        };
     };
   };
  }
