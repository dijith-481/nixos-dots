{
  description = "dijith's nixos config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:nix-community/stylix";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self,nixpkgs,home-manager,zen-browser,stylix, ... }:{
    nixosConfigurations.nixos-celestia = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit zen-browser stylix; };
      modules = [
        ./configuration.nix
        stylix.nixosModules.stylix

               home-manager.nixosModules.home-manager
        {
            home-manager ={
            useGlobalPkgs = true;
            useUserPackages = true;
            users.dijith = import ./home.nix ;
            extraSpecialArgs = {inherit  zen-browser;};
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
