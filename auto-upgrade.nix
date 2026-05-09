{ config, lib, pkgs, name, hosts, ... }:

let
  isMain = name == "main";
  deployKey = "/root/.ssh/nixos-deploy_ed25519";
  flake = "github:sileanth/nixosik-server";

  mkDeployService = targetName: targetHost: {
    description = "Deploy ${targetName} NixOS configuration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      config.nix.package
      config.programs.ssh.package
      pkgs.gitMinimal
    ];
    environment.NIX_SSHOPTS = "-i ${deployKey} -o StrictHostKeyChecking=yes";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch \
        --flake ${flake}#${targetName} \
        --target-host sileanth@${targetHost.vpnIp} \
        --use-substitutes \
        --sudo \
        --print-build-logs
    '';
  };

  mkDeployTimer = serviceName: calendar: {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = calendar;
      Persistent = true;
      RandomizedDelaySec = "10min";
      Unit = "${serviceName}.service";
    };
  };
in
{
  boot.binfmt.emulatedSystems = lib.mkIf isMain [ "x86_64-linux" ];

  system.autoUpgrade = lib.mkIf isMain {
    enable = true;
    flake = "${flake}#main";
    flags = [ "--print-build-logs" ];
    dates = "04:00";
    randomizedDelaySec = "10min";
    allowReboot = false;
    runGarbageCollection = true;
  };

  nix.settings.sandbox = false;
  nix.settings.filter-syscalls = false;

  systemd.services = lib.mkIf isMain {
    deploy-kotek = mkDeployService "kotek" hosts.kotek;
    deploy-piesek = mkDeployService "piesek" hosts.piesek;
  };

  systemd.timers = lib.mkIf isMain {
    deploy-kotek = mkDeployTimer "deploy-kotek" "*-*-* 04:30:00";
    deploy-piesek = mkDeployTimer "deploy-piesek" "*-*-* 05:00:00";
  };
}
