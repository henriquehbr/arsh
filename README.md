# arsh

> Personal Arch Linux installation script

## Requirements

- An computer with UEFI support, at least 512MB of RAM and 2GB of disk space
- Any bootable media (USB drive) with at least 512MB of storage space ([Recommended way](#recommended-way))
- [`dash`](https://archlinux.org/packages/core/x86_64/dash/) ([Script-only way](#script-only-way))

> You can verify that by running `ls /sys/firmware | grep efi`, if a directory called `efi` is returned, then you're good to go

## Installation

#### Recommended way

It's strongly advised to use arshiso instead of Arch's official ones, due to the fact that the first is way more minimal (370MB) in contrast to the latter (755MB) and contain only the bare-minimum required packages to setup the whole installation process, resulting in a much smoother and fast experience, it can be found on the `arshiso` directory

For more technical details regarding arshiso, consider checking the `README` on `archiso` directory

#### Script-only

```bash
curl -L git.io/J3BJ9 -o arsh
```

> `-L` follows redirections

## About the `arsh` script

This hand-crafted **dash** script performs a slightly opinionated and absolutely-bare-bones LUKS encrypted Arch installation, having only the extreme basics and essentials to make it bootable and connected to the internet, by default, the partitioning is done as the following:

- Boot partition (`/dev/sda1`) 550MB
- Swap partition (`/dev/sda2`) `RAM + round(sqrt(RAM))`GB
- Root partition (`/dev/sda3`) Remaining space 

and when it comes to packages, only the following ones are installed:

- [`base`](https://archlinux.org/packages/core/any/base/) - Minimal package set to define a basic Arch Linux installation 
- [`linux`](https://archlinux.org/packages/testing/x86_64/linux/) - The Linux kernel and modules
- [`linux-firmware`](https://archlinux.org/packages/core/any/linux-firmware/) - Firmware files for Linux
- [`grub`](https://archlinux.org/packages/core/x86_64/grub/) - GNU Grand Unified Bootloader
- [`networkmanager`](https://archlinux.org/packages/extra/x86_64/networkmanager/) - Network connection manager and user applications
- [`intel-ucode`](https://archlinux.org/packages/extra/any/intel-ucode/) or [`amd-ucode`](https://archlinux.org/packages/core/any/amd-ucode/) (depending on your CPU) - Microcode update files/images for Intel/AMD CPU's

> As pointed by their links, every single one of these 6 packages can be found on the official Arch package repositories
