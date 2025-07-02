default:
  just --list

update:
	nix flake update --commit-lock-file

switch:
  sudo nixos-rebuild switch --flake .#

build-boot:
	sudo nixos-rebuild switch --flake .# --install-bootloader

clean:
	sudo nix-collect-garbage -d
