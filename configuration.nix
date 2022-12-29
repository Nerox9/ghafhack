{ pkgs, ... }:
{
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "fi";
  };

  environment.systemPackages = with pkgs; [
  ];

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "22.11";
}
