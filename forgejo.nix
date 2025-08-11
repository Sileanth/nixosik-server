{pkgs, ...}: {
	services.forgejo = {
		useWizard = true;
		enable = true;
		lfs.enable = true;
		database = {
			type = "sqlite3";
		};
		settings = {
			server = {
				DOMAIN = "git.sileanth.pl";
				ROOT_URL = "https://git.sileanth.pl/";
				HTTP_PORT = "3011";

			};

		};


	};

}
