{
  description = "Roblox luau development environment flake";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    rokit-nix.url = "github:CapedBojji/rokit-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, devenv-root, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages.default = pkgs.hello;

        devenv.shells.default = rec {
          devenv.root =
            let
              devenvRootFileContent = builtins.readFile devenv-root.outPath;
            in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

          name = "Roblox-TS Dev Shell";

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = [ 
            inputs.rokit-nix.packages.${system}.default
          ];

          scripts = {};

          process.managers.process-compose.settings = {
            processes = {
            };
          };

          env = {
            ROKIT_ROOT = 
            let
              devenvRootFileContent = builtins.readFile devenv-root.outPath;
            in
            pkgs.lib.mkIf (devenvRootFileContent != "") "${devenvRootFileContent}/.rokit";
          };

          enterShell = ''
                mkdir -p ${config.devenv.shells.default.env.ROKIT_ROOT}
                echo "🚀 Welcome to enhanced-dev-shell!"
                echo

                # Display Packages Section
                echo "📦 Packages in this Shell:"
                echo "--------------------------"
                printf '%s\n' ${
                  builtins.concatStringsSep "\n" (
                    map (
                      pkg:
                      ''"${pkg.pname}-${pkg.version or "unknown"} | ${
                        pkg.meta.description or "No description provided"
                      }"''
                    ) packages
                  )
                } | \
                ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' | \
                ${pkgs.util-linuxMinimal}/bin/column -t | \
                ${pkgs.gnused}/bin/sed -e 's|^|  📦 |' -e 's|••| |g'
                echo

                # Display Scripts Section
                echo "💡 Helper Scripts Available:"
                echo "---------------------------"
                printf '%s\n' ${
                  builtins.concatStringsSep "\n" (
                    map (
                      name:
                      let
                        script = scripts.${name};
                        description =
                          if pkgs.lib.strings.stringLength (script.description or "") > 0 then
                            script.description
                          else
                            "No description provided";
                      in
                      ''"${name} | ${description}"''
                    ) (builtins.attrNames scripts)
                  )
                } | \
                ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' | \
                ${pkgs.util-linuxMinimal}/bin/column -t | \
                ${pkgs.gnused}/bin/sed -e 's|^|  💡 |' -e 's|••| |g'
              '';
        };

      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
