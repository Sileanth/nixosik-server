{pkgs, ip4, ...}: {
  
  

  services.tailscale = {
    enable = true;
    openFirewall = true;


  };


}
