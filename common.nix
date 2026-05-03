{ config, lib, pkgs, hostInfo, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "sileanth" ];
  


  services.resolved.enable = true;
  time.timeZone = "UTC";

  users.users.sileanth = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
      neovim
      htop
      git
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdfUTsub/EKUIWhhAmTzhfjhFsdNzt53cNxGtC4h1Sa lukas@liga"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  system.stateVersion = "25.11";
}
