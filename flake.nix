{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    # Ensure nixpkgs follows nix-ros-overlay's version to avoid compatibility issues
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; 
  };

  outputs = { self, nixpkgs, nix-ros-overlay, vscode-server, ... }@inputs:
    let 
      pkgsOverride = (inputs: {
        nixpkgs = {
          config.allowUnfree = true;
            overlays = [
              nix-ros-overlay.overlays.default
            ];
          };
        });
    in { 
      nixosConfigurations."68a49c16a4dda91de95f8bec" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          # Base NixOS modules
          ./configuration.nix 
          vscode-server.nixosModules.default
          # Add the nix-ros-overlay to your system overlays
          { nixpkgs.overlays = [ nix-ros-overlay.overlays.default ]; }
          # You may also need to include nixos-hardware for specific Raspberry Pi 4 hardware support
          # nixos-hardware.nixosModules.raspberry-pi-4 
        ];
        # Further configuration specific to your Raspberry Pi and ROS needs
      };

      devShells."aarch64-linux".default = pkgs.mkShell {
        name = "Polyflow DevShell";
        packages = [
          pkgs.colcon
          # ... other non-ROS packages
          (with pkgs.rosPackages.humble; buildEnv {
            paths = [
              ros-core
              # ... other ROS packages
            ];
          })
        ];
      };

      substituters = https://ros.cachix.org;
      trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=;
    };
}