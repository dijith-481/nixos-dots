{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix

    inputs.home-manager.nixosModules.home-manager
    ({ pkgs, ... }: {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.dijith = import ./home.nix;
        extraSpecialArgs = { inherit inputs; };
        # A fixed extension blocks activation as soon as a previous backup
        # exists. Retain older copies instead of clobbering them.
        backupCommand = pkgs.lib.getExe (pkgs.writeShellApplication {
          name = "home-manager-backup";
          runtimeInputs = [ pkgs.coreutils ];
          text = builtins.readFile ../../scripts/home-manager-backup.sh;
        });
      };
    })
  ];

}
