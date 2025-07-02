{pkgs, ip4, ...}: {
  
  
  networking.firewall.allowedTCPPorts = [ 5984 ];

  services.couchdb = {
    enable = true;


  };


}
