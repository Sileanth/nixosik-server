 {
   inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
     disko.url = "github:nix-community/disko/latest";
     disko.inputs.nixpkgs.follows = "nixpkgs";

   };

   outputs = { nixpkgs, disko,... }: {
     nixosConfigurations = {
       main  = let
	vars = {
		ip4 = "135.181.87.151";
		ip6 = "2a01:4f9:c012:f993::1";
	};
       in nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { inherit vars; };
         modules = [
           disko.nixosModules.disko
           ./configuration.nix
         ];
       };
     };
   };
 }
