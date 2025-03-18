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
            ml-ops.devcontainer = devcontainer: {
              environmentVariables = lib.mkIf (pkgs.stdenv.isLinux) {
                # DeepSpeed needs this to compile with -march=native
                NIX_ENFORCE_NO_NATIVE = "0";

                # Required by DeepSpeed
                LDFLAGS = "-L${lib.escapeShellArg pkgs.libaio}/lib";
                # LDFLAGS = "-L${lib.escapeShellArg pkgs.libaio}/lib -L${lib.escapeShellArg devcontainer.config.cuda.home}/lib";
              };
              cuda.packages = [
                # Required by DeepSpeed
                devcontainer.config.cuda.cudaPackages.libcufile.lib
                devcontainer.config.cuda.cudaPackages.libcurand.lib
                devcontainer.config.cuda.cudaPackages.cuda_nvcc
              ];
              devenvShellModule = {

                processes.jupyter-lab-collaborative.exec = ''
                  poetry run jupyter-lab --collaborative
                '';

                packages = [
                  pkgs.nixpkgs-fmt
                  pkgs.nixfmt-rfc-style

                  # DeepSpeed needs mpi4py, which needs OpenMPI or MPICH
                  pkgs.mpi

                  # DeepSpeed needs ninja
                  pkgs.ninja
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
