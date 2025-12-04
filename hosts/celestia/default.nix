{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.dijith = import ./home.nix;
        extraSpecialArgs = { inherit inputs; };
        backupFileExtension = "backup";
      };
    }
  ];

}
