{pkgs, ...}: {
  
	system.autoUpgrade = {
		enable = true;
		dates = "04:00";
		flake = "github:sileanth/nixosik-server";

	};

}
