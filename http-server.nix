{pkgs, ...}: {

   networking.firewall.allowedTCPPorts = [ 80 443];


   services.nginx = {
       enable = true;
  listen = [
    { addr = "0.0.0.0"; port = 80; }
    { addr = "[::]"; port = 80; }
  ];
       virtualHosts."sileanth.eu" = {
          return = "200 '<html><body>It works</body></html>'";
      extraConfig = ''
        default_type text/html;
      '';
        };
     };
  }
