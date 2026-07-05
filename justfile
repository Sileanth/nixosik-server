set shell := ["bash", "-cu"]

ssh_opts := "-o Compression=no -o ControlMaster=auto -o ControlPath=~/.ssh/control-%r@%h:%p -o ControlPersist=10m"

default:
    @just --list

kotek:
    NIX_SSHOPTS='{{ssh_opts}}' nixos-rebuild switch \
      --flake .#kotek \
      --target-host kotek \
      --use-remote-sudo

piesek:
    NIX_SSHOPTS='{{ssh_opts}}' nixos-rebuild switch \
      --flake .#piesek \
      --target-host piesek \
      --use-remote-sudo

main:
    ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
    ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote \
    ansible-playbook -i ansible/inventory.ini ansible/update.yml

all: main kotek piesek
