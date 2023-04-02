{
  description =
    "Linux userspace driver to enable and disable the touchpads on TongFang/Uniwill laptops using a HID command";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }:
    let
      # to work with older version of flakes
      lastModifiedDate =
        self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });

    in {

      # A Nixpkgs overlay.
      overlay = final: prev: {
        tuxedo-touchpad-switch = with final;
          stdenv.mkDerivation rec {
            pname = "tuxedo-touchpad-switch";
            inherit version;

            src = ./.;

            nativeBuildInputs = [
              autoreconfHook
              cmake
              libudev
              glib
              pkg-config
              pcre
              util-linux
              libselinux
              libsepol
            ];
          };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) tuxedo-touchpad-switch; });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage =
        forAllSystems (system: self.packages.${system}.tuxedo-touchpad-switch);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.tuxedo-touchpad-switch = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlay ];

        environment.systemPackages = [ pkgs.tuxedo-touchpad-switch ];
        environment.etc = [ self ];

        #systemd.services = { ... };
      };
    };
}
