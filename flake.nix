 {
   inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
   };

   outputs = { nixpkgs, ... }: {
     nixosConfigurations = {
       hetzner = let
	vars = {
		ip4 = "135.181.87.151";
		ip6 = "2a01:4f9:c012:f993::1";
	};
       in nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { inherit vars; };
         modules = [
           ./configuration.nix
           ./http-server.nix
           ./bind.nix
           ./im-tunnel.nix
         ];
       };
     };
   };
 }
