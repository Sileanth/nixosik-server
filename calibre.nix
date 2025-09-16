{pkgs, config, ...}: let
  cfg = config.services.forgejo;
in {
  services.calibre-server = {
    enable = true;
    port = 3013;
    # u need to create lbirary before starting service
    # wget http://www.gutenberg.org/ebooks/1342.kindle.noimages -O pride.mobi
    # sudo calibredb add pride.mobi  --library-path /persist/calibre-server/library
    libraries = [
      /persist/calibre-server/

    ];
    auth = {
      enable = true;
      # before enabling service create userdb
      # calibre-server --userdb /persist/calibre-server/users.sqlite --manage-user
      userDb = /persist/calibre-server/users.sqlite;


    };

  };
}
