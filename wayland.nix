{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    weston
  ];
  hardware.opengl.enable = true;
}
