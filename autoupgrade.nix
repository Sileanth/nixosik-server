{pkgs, ...}: {
  
	system.autoUpgrade = {
		enable = true;
		dates = "04:00";
		flake = "github:sileanth/nixosik-server";

	};


  nix.settings.auto-optimise-store = true;


  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


}
