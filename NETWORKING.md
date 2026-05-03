# Networking Documentation

This project uses a modular NixOS configuration to manage networking across multiple hosts.

## Configuration Strategy

The networking setup is split into three main components:

1.  **Source Data ([hosts.nix](./hosts.nix))**: Contains all host-specific network metadata including Private/Public IPs, Interface names, and SSH host keys.
2.  **Logic ([networking.nix](./networking.nix))**: A generic module that implements static networking using `systemd-networkd`. It consumes the `hostInfo` record passed from the flake.
3.  **Orchestration ([flake.nix](./flake.nix))**: Maps the host data to the configuration modules, injecting the correct metadata into each system.

## Static Networking Details

- **Backend**: `systemd-networkd` (defined in `networking.nix`).
- **Gateway/DNS**: Standard Oracle VCN defaults (`10.0.0.1` / `169.254.169.254`) are applied globally in the networking module.
- **Interfaces**: Mapped dynamically per-host (e.g., `ens3` for x86 nodes, `enp0s6` for ARM nodes).

Refer to [hosts.nix](./hosts.nix) for the current IP assignments and hardware interface mappings.
