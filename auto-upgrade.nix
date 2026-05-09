{ lib, name, hostInfo, ... }:

let
  isMain = name == "main";
  isX86Node = hostInfo.arch == "x86_64-linux";
  mainVpnIp = "10.200.0.1";
in
{
  boot.binfmt.emulatedSystems = lib.mkIf isMain [ "x86_64-linux" ];

  nix.distributedBuilds = lib.mkIf isX86Node true;
  nix.buildMachines = lib.mkIf isX86Node [
    {
      hostName = mainVpnIp;
      protocol = "ssh-ng";
      system = "x86_64-linux";
      sshUser = "sileanth";
      sshKey = "/root/.ssh/nix-builder_ed25519";
      maxJobs = 1;
      speedFactor = 1;
    }
  ];
  nix.settings = lib.mkIf isX86Node {
    builders-use-substitutes = true;
    max-jobs = 0;
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:sileanth/nixosik-server#${name}";
    flags = [ "--print-build-logs" ];
    dates =
      if isMain then
        "04:00"
      else if name == "kotek" then
        "04:30"
      else if name == "piesek" then
        "05:00"
      else
        "05:30";
    randomizedDelaySec = "10min";
    allowReboot = false;
    runGarbageCollection = true;
  };
}
