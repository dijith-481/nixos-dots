{
  description = "dijith's nixos config";
  inputs = {

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Brave was restored on master after its temporary removal from unstable.
    # Use only its maintained recipe, built against our regular package set.
    brave-nixpkgs = {
      url = "github:NixOS/nixpkgs/master";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:nix-community/stylix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    # Official Delta Linux binaries. `follows` keeps Delta on our nixpkgs so its
    # bundled glibc matches the host Mesa/LLVM stack loaded from
    # /run/opengl-driver; a stale pin breaks GPU adapter detection at startup.
    delta = {
      url = "github:zed-industries/delta-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    overlays.default = nixpkgs.lib.composeManyExtensions [
      (import ./pkgs)
      (final: _prev: {
        brave = (final.callPackage
          "${inputs.brave-nixpkgs}/pkgs/applications/networking/browsers/brave"
          { }).brave;
      })
    ];

    # `nix build .#claude-desktop`, `nix run .#dots -- help`, `nix run .#update-sources`
    packages.${system} = nixpkgs.lib.genAttrs pkgs.dotsApps (name: pkgs.${name}) // {
      inherit (pkgs) brave dots update-sources nix-helper;
    };

    # Local dependency workarounds must not silently replace cached Rust builds.
    # Evaluate with `nix flake check --no-build`; no cache access is needed.
    checks.${system}.upstream-rust-packages =
      let
        upstream = import nixpkgs { inherit system; };
        rustOutputs = p: [
          p.anyrun.outPath
          p.scooter.outPath
          p.figma-agent.outPath
          p.vimPlugins.fff-nvim.outPath
          p.vimPlugins.fff-nvim.fff-nvim-lib.outPath
        ];
        systemPkgs = self.nixosConfigurations.nixos-celestia.pkgs;
      in
      assert nixpkgs.lib.assertMsg (rustOutputs systemPkgs == rustOutputs upstream)
        "Rust package overrides differ from nixpkgs and may bypass the official binary cache";
      pkgs.runCommand "upstream-rust-packages" { } "touch $out";

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
