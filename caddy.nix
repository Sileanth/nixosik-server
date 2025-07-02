{pkgs, ip4, ...}: {
  

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
