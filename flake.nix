{
  nixConfig = {
    extra-substituters = [
      "http://binarycache.vedenemo.dev"
    ];
    extra-trusted-public-keys = [
      "binarycache.vedenemo.dev:Yclq5TKpx2vK7WVugbdP0jpln0/dPHrbUYfsH3UXIps="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jetpack-nixos = {
      url = "github:anduril/jetpack-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nixos-generators, microvm, jetpack-nixos, ... }:
    let
      microvm-host-config = ({ system }: { config, lib, pkgs, ... }:
        {
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          microvm = {
            host.enable = true;
            vms = {
              "${system}-netvm" = {
                flake = self;
                autostart = true;
              };
              "${system}-appvm-elinks" = {
                flake = self;
                autostart = true;
              };
            };
          };

          systemd.network = {
            enable = true;
            netdevs.virbr0.netdevConfig = {
              Kind = "bridge";
              Name = "virbr0";
            };
            networks.virbr0 = {
              matchConfig.Name = "virbr0";
              networkConfig = {
                DHCPServer = true;
              };
              addresses = [{
                addressConfig.Address = "10.10.0.1/24";
              }];
            };
            networks.microvm-eth0 = {
              matchConfig.Name = "qemu*";
              networkConfig.Bridge = "virbr0";
            };
          };
          networking.firewall.allowedUDPPorts = [ 67 ];
          networking.nat = {
            enable = true;
            enableIPv6 = false;
            internalInterfaces = [ "virbr0" ];
          };
        });
      systems = with flake-utils.lib.system; [
        x86_64-linux
        aarch64-linux
      ];
      makeVMs = { system }: {
        "${system}-netvm" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            {
              system.stateVersion = "22.11";
              networking.hostName = "netvm";
              users.users.root.password = "netvm";
              networking.useDHCP = true;
              microvm = {
                # TODO: Add another interface
                interfaces = [
                  {
                    type = "user";
                    id = "qemu0";
                    mac = "02:00:00:01:01:01";
                  }
                  {
                    type = "tap";
                    id = "tap0";
                    mac = "02:00:00:01:02:01";
                  }
                ];
                volumes = [{
                  mountPoint = "/var";
                  image = "var.img";
                  size = 256;
                }];
                shares = [{
                  # use "virtiofs" for MicroVMs that are started by systemd
		  proto = "virtiofs";
                  # proto = "9p";
                  tag = "ro-store";
                  # a host's /nix/store will be picked up so that the
                  # size of the /dev/vda can be reduced.
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                }];
                socket = "control.socket";
                # relevant for delarative MicroVM management
                # hypervisor = "crosvm";
                hypervisor = "qemu";
              };
            }
          ];
        };
        "${system}-appvm-elinks" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            ({ pkgs, ... }:
              {
                environment.systemPackages = [ pkgs.elinks ];
                system.stateVersion = "22.11";
                networking.hostName = "appvm-elinks";
                networking.useDHCP = true;
                users.users.root.password = "elinks";
                microvm = {
                  interfaces = [
                    {
                      type = "user";
                      id = "qemu1";
                      mac = "02:00:00:01:01:02";
                    }
                    # {
                    #   type = "tap";
                    #   id = "tap1";
                    #   mac = "02:00:00:01:02:02";
                    # }
                  ];
                  volumes = [{
                    mountPoint = "/var";
                    image = "var.img";
                    size = 256;
                  }];
                  shares = [{
                    # use "virtiofs" for MicroVMs that are started by systemd
		    proto = "virtiofs";
                    # proto = "9p";
                    tag = "ro-store";
                    # a host's /nix/store will be picked up so that the
                    # size of the /dev/vda can be reduced.
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                  }];
                  socket = "control.socket";
                  # relevant for delarative MicroVM management
                  # hypervisor = "crosvm";
                  hypervisor = "qemu";
                };
              })
          ];
        };
      };
    in
    # VMs
    flake-utils.lib.eachSystem systems
      (system:
        {
          packages.${system}."${system}-netvm" =
            let
              inherit (self.nixosConfigurations."${system}-netvm") config;
              # quickly build with another hypervisor if this MicroVM is built as a package
              # hypervisor = "crosvm";
              hypervisor = "qemu";
            in
            config.microvm.runner.${hypervisor};

          packages.${system}."${system}-appvm-elinks" =
            let
              inherit (self.nixosConfigurations."${system}-appvm-elinks") config;
              # quickly build with another hypervisor if this MicroVM is built as a package
              # hypervisor = "crosvm";
	      hypervisor = "qemu";
            in
            config.microvm.runner.${hypervisor};

        }) //
    {
      # Create VM nixosConfigurations for every target system.
      # What you see below means the same as:
      # nixosConfigurations = makeVMs { system = "x86_64-linux"; } // makeVMs { system = "aarch64-linux"; };
      nixosConfigurations = nixpkgs.lib.foldr (a: b: a // b) { } (map (system: makeVMs { inherit system; }) systems);

      # Final target images
      packages.x86_64-linux.vm = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./debug.nix
          ./wayland.nix

          microvm.nixosModules.host
          (microvm-host-config { system = "x86_64-linux"; })
        ];
        format = "vm";
      };

      packages.aarch64-linux.orin = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
          ./debug.nix
          ./wayland.nix

          (jetpack-nixos.nixosModules.default)
          ./nvidia-jetson-orin.nix

          microvm.nixosModules.host
          (microvm-host-config { system = "aarch64-linux"; })
        ];
        format = "raw-efi";
      };
    };
}
