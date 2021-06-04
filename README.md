# arsh

> Personal Arch Linux installation script

## Requirements

- An computer with UEFI support, at least 512MB of RAM and 2GB of disk space
- Any bootable media (USB drive) with at least 512MB of storage space ([Recommended way](#recommended-way))
- [`dash`](https://archlinux.org/packages/core/x86_64/dash/) ([Script-only way](#script-only-way))

> You can verify that by running `ls /sys/firmware | grep efi`, if a directory called `efi` is returned, then you're good to go

## Installation

#### Recommended way

It's strongly advised to use arshiso instead of Arch's official ones, due to the fact that the first is way more minimal (370MB) in contrast to the latter (755MB) and contain only the bare-minimum required packages to setup the whole installation process, resulting in a much smoother and fast experience

In order to generate arshiso, clone this repository and run:

```
$ make iso
```

Basically, what this Makefile task does is:

- Delete any already existing ISO and it's generated files
- The `arsh` script will also be copied to the ISO root directory
- The ISO file is generated on `arshiso/out/arshiso-yyyy.mm.dd-x86_64.iso`

For more technical details regarding arshiso, consider checking the `README` on `archiso` directory

#### Script-only

```bash
curl -L git.io/J3BJ9 -o arsh
```

> `-L` follows redirections

## About the `arsh` script

This hand-crafted **dash** script performs a slightly opinionated and absolutely-bare-bones LUKS encrypted Arch installation, having only the extreme basics and essentials to make it bootable and connected to the internet, by default, the partitioning is done as the following:

#### Partitioning

- Boot partition (`/dev/sda1`) 550MB
- Swap partition (`/dev/sda2`) `RAM + round(sqrt(RAM))`GB
- Root partition (`/dev/sda3`) Remaining space 

#### Base packages

When it comes to essential packages, only the following ones are installed:

- [`base`](https://archlinux.org/packages/core/any/base/) - Minimal package set to define a basic Arch Linux installation 
- [`linux`](https://archlinux.org/packages/testing/x86_64/linux/) - The Linux kernel and modules
- [`linux-firmware`](https://archlinux.org/packages/core/any/linux-firmware/) - Firmware files for Linux
- [`grub`](https://archlinux.org/packages/core/x86_64/grub/) - GNU Grand Unified Bootloader
- [`networkmanager`](https://archlinux.org/packages/extra/x86_64/networkmanager/) - Network connection manager and user applications
- [`dash`](https://archlinux.org/packages/core/x86_64/dash/) - POSIX compliant shell that aims to be as small as possible
- [`intel-ucode`](https://archlinux.org/packages/extra/any/intel-ucode/) or [`amd-ucode`](https://archlinux.org/packages/core/any/amd-ucode/) (depending on your CPU) - Microcode update files/images for Intel/AMD CPU's

> As pointed by their links, every single one of these packages can be found on the official Arch package repositories

#### Rice packages

The following packages are the ones that makes the system usable as a daily driver:

- [`git`](https://archlinux.org/packages/extra/x86_64/git/) - The fast distributed version control system
- [`neovim`](https://archlinux.org/packages/community/x86_64/neovim/) - Fork of Vim aiming to improve user experience, plugins, and GUIs
- [`unzip`](https://archlinux.org/packages/extra/x86_64/unzip/) - For extracting and viewing files in .zip archives
- [`stow`](https://archlinux.org/packages/community/any/stow/) - Manage installation of multiple softwares in the same directory tree
- [`opendoas`](https://archlinux.org/packages/community/x86_64/opendoas/) - Run commands as super user or another user
- [`xorg-xinit`](https://archlinux.org/packages/extra/x86_64/xorg-xinit/) - X.Org initialisation program
- [`dmenu`](https://archlinux.org/packages/community/x86_64/dmenu/) - Generic menu for X
- [`pulseaudio`](https://archlinux.org/packages/extra/x86_64/pulseaudio/) - A featureful, general-purpose sound server
- [`alsa-utils`](https://archlinux.org/packages/extra/x86_64/alsa-utils/) - Advanced Linux Sound Architecture - Utilities
- [`inotify-tools`](https://archlinux.org/packages/community/x86_64/inotify-tools/) - inotify-tools is a C library and a set of command-line programs for Linux providing a simple interface to inotify
- [`reflector`](https://archlinux.org/packages/community/any/reflector/) - A Python 3 module and script to retrieve and filter the latest Pacman mirror list
- [`fakeroot`](https://archlinux.org/packages/core/x86_64/fakeroot/) - Tool for simulating superuser privileges
- [`binutils`](https://archlinux.org/packages/core/x86_64/binutils/) - A set of programs to assemble and manipulate binary and object files
- [`exa`](https://archlinux.org/packages/community/x86_64/exa/) - ls replacement
- [`expect`](https://archlinux.org/packages/extra/x86_64/expect/) - A tool for automating interactive applications
- [`xorg`](https://archlinux.org/groups/x86_64/xorg/) - X.org package group
