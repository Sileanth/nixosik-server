{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
	./disk.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "main"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.sileanth = {
	openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdfUTsub/EKUIWhhAmTzhfjhFsdNzt53cNxGtC4h1Sa lukas@liga"
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhmckjZU0namZrSdGnKd1sjh4VTawZSPUggqq1Twf04 your_email@example.com"
	];
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
      python3
       tree
	just
     ];
   };


   environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	git
     wget
   ];


  # Enable the OpenSSH daemon.
  services.fail2ban = {
    enable = true;
  };
  services.openssh = {
	enable = true;
	settings = {
		PasswordAuthentication = false;
	};
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}

