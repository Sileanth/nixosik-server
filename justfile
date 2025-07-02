default:
  just --list

remote:
  ssh main "cd nixosik-server; git pull; just switch"

update:
	nix flake update --commit-lock-file

switch:
  sudo nixos-rebuild switch --flake .#

build-boot:
	sudo nixos-rebuild switch --flake .# --install-bootloader

clean:
	sudo nix-collect-garbage -d
