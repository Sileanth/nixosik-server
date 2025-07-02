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
		ip4 = "84.235.172.161";
	};
       in nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { inherit vars; };
         modules = [
           disko.nixosModules.disko
           ./configuration.nix
           ./caddy.nix
           ./couchdb.nix
         ];
       };
     };
   };
 }
