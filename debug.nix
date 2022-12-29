{ pkgs, ... }:
{
  # Set root username to password
  users.users.root.initialHashedPassword = "$6$nTPPvL0.lsNyV4rE$wTYhG57jtFj8S.RkQ2BtYn8pLCrt9RiQTM9FTEWInej1UNGCyKuva7WBIKE0BsmBnFMwDpzivmva4YthHeEDh/";
  services.getty.greetingLine = "Debug configuration enabled. Password for root is password.";

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

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfsdOINT+oNeUKA+RIVqqykYHS0Wt+rD/toK7GhXCOh mika@nixos-t14"
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
    ];
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };
}
