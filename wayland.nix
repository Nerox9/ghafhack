{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    weston
  ];
}
