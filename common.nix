{ config, lib, pkgs, hostInfo, hosts, name, ... }:

let
  knownSshHosts = lib.filterAttrs (_: host: host ? sshKey) hosts;
  builderPublicKeys =
    lib.optionals (name == "main") (
      lib.mapAttrsToList (_: host: host.builderPubKey) (
        lib.filterAttrs (_: host: host ? builderPubKey) hosts
      )
    );
in
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
    ] ++ builderPublicKeys;
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
    daemonSettings.Definition.dbfile = "/run/fail2ban/fail2ban.sqlite3";
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
    allowSFTP = true;
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

  programs.ssh.knownHosts = lib.mapAttrs (hostName: host: {
    hostNames =
      [ hostName ]
      ++ lib.optionals (host ? public) [ host.public ]
      ++ lib.optionals (host ? private) [ host.private ]
      ++ lib.optionals (host ? vpnIp) [ host.vpnIp ];
    publicKey = host.sshKey;
  }) knownSshHosts;

  system.stateVersion = "25.11";
}
