{pkgs, config, ...}: let
  cfg = config.services.forgejo;
in {
  services.calibre-server = {
    enable = true;
    port = 3013;
    auth = {
      enable = true;
      # before enabling service create userdb
      # calibre-server --userdb /persist/calibre-server/users.sqlite --manage-user
      userDb = /persist/calibre-server/users.sqlite;


    };

  };
}
