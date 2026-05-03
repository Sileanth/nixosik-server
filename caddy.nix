{ config, lib, pkgs, name, ... }:

{
  config = lib.mkIf (name == "main") {
    services.caddy = {
      enable = true;
      virtualHosts."sileanth.pl".extraConfig = ''
        respond "Hello World"
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
