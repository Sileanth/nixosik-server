{pkgs, ip4, ...}: {
  
  
  networking.firewall.allowedTCPPorts = [ 80 443];
  services.caddy = {
    enable = true;

    virtualHosts = {
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
