{pkgs, ...}: {


  networking.firewall.allowedTCPPorts = [ 53 ];
  services.bind = {
    enable = true;
    zones = {
      "sileanth.eu" = {
        master = true;
        file = pkgs.writeText "sileanth.eu" ''
          $ORIGIN sileanth.eu.
          $TTL 3600
          @       IN      SOA      ns1.sileanth.eu. admin.sileanth.eu. (
            40 ; Serial
            600            ; Refresh
            120           ; Retry
            3600            ; Expire
            3600 ) ; Negative Cache TTL
          ;

          ; Name servers
          sileanth.eu.  IN  NS  ns1.sileanth.eu.
          sileanth.eu.  IN  NS  ns2.sileanth.eu.


          ns1 IN  A 135.181.87.151
          ns2 IN  A 135.181.87.151 ; to change



          @ IN  A 135.181.87.151
          tetris IN  A 135.181.87.151
          blog IN  A 135.181.87.151
          sklep IN  A 135.181.87.151



        '';
      };
    };
    extraOptions = ''
      recursion no;
    '';
  };

}
