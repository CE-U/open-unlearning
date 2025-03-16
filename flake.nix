{
  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    systems.url = "github:nix-systems/default-linux";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-ml-ops.url = "github:Atry/nix-ml-ops";
    nix-ml-ops.inputs.systems.follows = "systems";
    nix-ml-ops.inputs.devenv-root.follows = "devenv-root";
  };
  outputs =
    inputs@{ nix-ml-ops, ... }:
    nix-ml-ops.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          nix-ml-ops.flakeModules.devcontainer
          nix-ml-ops.flakeModules.nixIde
          nix-ml-ops.flakeModules.nixLd
          nix-ml-ops.flakeModules.cuda
          nix-ml-ops.flakeModules.pythonVscode
          nix-ml-ops.flakeModules.ldFallbackManylinux
          nix-ml-ops.flakeModules.devcontainerNix
        ];
        perSystem =
          {
            pkgs,
            config,
            lib,
            system,
            inputs',
            ...
          }:
          {
            ml-ops.devcontainer = {
              devenvShellModule = {

                processes.jupyter-lab-collaborative.exec = ''
                  poetry run jupyter-lab --collaborative
                '';

                packages = [
                  pkgs.nixpkgs-fmt
                  pkgs.nixfmt-rfc-style
                ];
                languages = {
                  c.enable = true;
                  python = {
                    poetry.enable = true;
                    enable = true;
                  };
                };
              };
            };

          };
      }
    );
}
