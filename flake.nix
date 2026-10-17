{
  description = "dijith's nixos config";
  inputs = {

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:nix-community/stylix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixos-hardware, stylix, self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
    in
    {

    # Pinned upstream apps: recipes in pkgs/sources.toml, pins in pkgs/sources.lock.json.
    overlays.default = import ./pkgs;

    # `nix build .#claude-desktop`, `nix run .#dots -- help`, `nix run .#update-sources`
    packages.${system} = nixpkgs.lib.genAttrs pkgs.dotsApps (name: pkgs.${name}) // {
      inherit (pkgs) dots update-sources;
    };

    nixosConfigurations = {
      nixos-celestia = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/celestia

          "${nixos-hardware}/common/cpu/intel/meteor-lake"
          "${nixos-hardware}/common/pc/laptop"
          "${nixos-hardware}/common/pc/ssd"
          stylix.nixosModules.stylix
          inputs.niri.nixosModules.niri

        ];
      };
    };
  };
}
