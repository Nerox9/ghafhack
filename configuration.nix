{ pkgs, ... }:
{
  # TODO: Separate some/most of the stuff to separate debug.nix

  # Enable only for debugging: Set root username to password
  users.users.root.initialHashedPassword = "$6$nTPPvL0.lsNyV4rE$wTYhG57jtFj8S.RkQ2BtYn8pLCrt9RiQTM9FTEWInej1UNGCyKuva7WBIKE0BsmBnFMwDpzivmva4YthHeEDh/";

  environment.systemPackages = with pkgs; [
    killall
    htop
    iotop
    iftop
    screen
    tmux

    curl
    wget
    pv

    ripgrep
    fzy
  ];

  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "fi";
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfsdOINT+oNeUKA+RIVqqykYHS0Wt+rD/toK7GhXCOh mika@nixos-t14"
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 # SSH
        	      ];
  };
  hardware.enableRedistributableFirmware = true;

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };

  system.stateVersion = "22.11";
}
