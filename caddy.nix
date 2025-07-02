{pkgs, ip4, ...}: {
  
  
  networking.firewall.allowedTCPPorts = [ 80 443];
  services.caddy = {
    enable = true;

    virtualHosts = {
      "sileanth.pl" = {
        extraConfig = ''
          respond "Hello, world!"
        '';
      };
    };
  };


}
