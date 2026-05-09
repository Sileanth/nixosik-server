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
      wireguard-tools
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdfUTsub/EKUIWhhAmTzhfjhFsdNzt53cNxGtC4h1Sa lukas@liga"
    ];
  };
  environment.systemPackages = with pkgs; [
    python3
  ];

  security.sudo.wheelNeedsPassword = false;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ 51820 ];
  };

  services.fail2ban = {
    enable = true;
    bantime = "1h";
    maxretry = 3;
    ignoreIP = [
      "10.0.0.0/8"
      "10.200.0.0/24"
    ];
    bantime-increment = {
      enable = true;
      maxtime = "24h";
      rndtime = "10m";
    };
    jails.sshd.settings = {
      mode = "aggressive";
      findtime = "10m";
      maxretry = 3;
    };
  };

  services.openssh = {
    enable = true;
    allowSFTP = false;
    openFirewall = false;
    settings = {
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";
      AllowUsers = [ "sileanth" ];
      AuthenticationMethods = "publickey";
      KbdInteractiveAuthentication = false;
      LoginGraceTime = 30;
      MaxAuthTries = 3;
      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      X11Forwarding = false;
    };
  };

  system.stateVersion = "25.11";
}
