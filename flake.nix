{
  description = "NixOS configuration for my VMs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: 
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    
    hosts = import ./hosts.nix;
    
    mkHost = name: hostInfo: nixpkgs.lib.nixosSystem {
      system = hostInfo.arch;
      specialArgs = { inherit hostInfo name hosts; };
      modules = [
        ./hardware/${name}-hardware.nix
        ./common.nix
        ./networking.nix
        ./bind.nix
        ./caddy.nix
        ./wireguard.nix
        ./auto-upgrade.nix
      ];
    };
    hostsToBuild = nixpkgs.lib.filterAttrs (n: v: !(v.isClient or false)) hosts;
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkHost hostsToBuild;

    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          ansible
          gemini-cli
          codex
          rsync
          dig
          openssh
        ];
        
        shellHook = ''
          echo "NixOS Server Management Shell"
          echo "Available tools: ansible, gemini-cli, codex"
          zsh
        '';
      };
    });
  };
}
