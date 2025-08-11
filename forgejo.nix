{pkgs, config, ...}: let
  cfg = config.services.forgejo;
in {
	services.forgejo = {
		enable = true;
		lfs.enable = true;
		database = {
			type = "sqlite3";
		};
		settings = {
			server = {
				DOMAIN = "git.sileanth.pl";
				ROOT_URL = "https://git.sileanth.pl/";
				HTTP_PORT = 3011;

			};

		};


	};

	systemd.services.forgejo.preStart = let 
  adminCmd = "${pkgs.lib.getExe cfg.package} admin user";
  path = "/secrets/forgejo";
  user = "sileanth"; # Note, Forgejo doesn't allow creation of an account named "admin"
in ''
  ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "$(tr -d '\n' < ${path})" || true
  ## uncomment this line to change an admin user which was already created
'';

}
