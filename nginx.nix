{ config, lib, pkgs, name, ... }:

{
  config = lib.mkIf (name == "main") {
    services.nginx = {
      enable = true;
      virtualHosts."sileanth.pl" = {
        locations."/" = {
          return = "200 'Hello World'";
          extraConfig = ''
            default_type text/plain;
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
