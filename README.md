Building
========

Prerequisities: Enable flakes

x86-64
------
    nix build .#packages.x86_64-linux.vm -o result-vm

    result-vm/bin/run-nixos-vm

NVIDIA Jetson Orin
------------------
    nix build .#packages.aarch64-linux.orin -o result-orin

    dd if=./result-orin/nixos.img of=/dev/YOUR_SD_CARD_OR_USB_DRIVE bs=32M
