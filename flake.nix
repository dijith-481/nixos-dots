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

  outputs = { nixpkgs, nixos-hardware, stylix, self, ... }@inputs: {

    overlays.default = final: prev: {
      vp = prev.callPackage ./pkgs/vp.nix { };
      antigravity = prev.callPackage ./pkgs/antigravity.nix { };
      chatgpt = prev.callPackage ./pkgs/chatgpt.nix { };
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
