# arsh

> Personal Arch Linux installation script

## Installation

```bash
curl -L git.io/J3BJ9 | bash
```

> `-L` follows redirections

## About

This hand-crafted script performs a slightly opinionated and absolutely-bare-bones LUKS encrypted Arch installation, having only the extreme basics and essentials to make it bootable and connected to the internet, by default, the partitioning is done as the following:

- Boot partition (`/dev/sda1`) 550MB
- Swap partition (`/dev/sda2`) RAM + round(sqrt(RAM))GB
- Root partition (`/dev/sda3`) Remaining space 

and when it comes to packages, only the following ones are installed:

- [`base`](https://archlinux.org/packages/core/any/base/) - Minimal package set to define a basic Arch Linux installation 
- [`linux`](https://archlinux.org/packages/testing/x86_64/linux/) - The Linux kernel and modules
- [`linux-firmware`](https://archlinux.org/packages/core/any/linux-firmware/) - Firmware files for Linux
- [`grub`](https://archlinux.org/packages/core/x86_64/grub/) - GNU Grand Unified Bootloader
- [`networkmanager`](https://archlinux.org/packages/extra/x86_64/networkmanager/) - Network connection manager and user applications
- [`intel-ucode`](https://archlinux.org/packages/extra/any/intel-ucode/) or [`amd-ucode`](https://archlinux.org/packages/core/any/amd-ucode/) (depending on your CPU) - Microcode update files/images for Intel/AMD CPU's

> As pointed by their links, every single one of these 6 packages can be found on the official Arch package repositories
