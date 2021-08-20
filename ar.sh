#!/bin/dash

#  _     _          
# | |   | |           Henrique Borges (henriquehbr)
# | |__ | |__  _ __   https://github.com/henriquehbr
# | '_ \| '_ \| '__|  https://henriquehbr.dev
# | | | | |_) | |     https://reddit.com/u/henriquehbr
# |_| |_|_.__/|_|

# Exit on errors
set -e

# ========== Configuration variables ==========

USER_NAME=""
LUKS_PARTITION_NAME=""
KEYMAP=""
LOCALE=""
HOSTNAME=""
TIMEZONE=""
MIRROR_COUNTRIES=""

# ========== DO NOT EDIT BELOW THIS LINE ==========

bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)

cpu_vendor=$(lscpu | grep GenuineIntel > /dev/null 2>&1 && echo intel || echo amd)
cpu_package="${cpu_vendor}-ucode"

# Calculate swap size based on the formula: RAM + round(sqrt(RAM))
ram=$(grep MemTotal /proc/meminfo | awk '{ print int($2 / 1000000) }')
swap=$(echo "$ram" | awk '{ print $1 + int(sqrt(8)) }')

boot_partition=/dev/sda1
swap_partition=/dev/sda2
root_partition=/dev/sda3

base_packages="base linux linux-firmware grub efibootmgr networkmanager dash $cpu_package"
rice_packages="git neovim unzip opendoas xorg-xauth sx dmenu pulseaudio alsa-utils inotify-tools reflector expect xorg bspwm sxhkd xdo base-devel zsh zsh-completions scrot fzf dunst libnotify"
aur_packages="lemonbar-xft-git brave-bin"

# ========== Functions ==========

infobox() {
	border_length=$(( ${#1} + 2 ))
	printf "\n${bold}%${border_length}s\n" | tr " " "="
	echo " $1 "
	printf "%${border_length}s${normal}\n\n" | tr " " "="
}

password_prompt() {
	while :; do
		stty -echo
		printf "\n%s" "$2"
		read -r password
		printf "\n%s" "$3"
		read -r repeat_password
		stty echo
		echo
		if [ -z "$password" ] || [ -z "$repeat_password" ]; then
			printf "\nPassword cannot be empty, please, try again"
			read -r retry
		elif [ "$password" = "$repeat_password" ]; then
			export "$1"="$password"
			break
		else
			printf "\nPasswords do not match, please, try again"
			read -r retry
		fi
	done
}

complete_steps() {
	for step in "$@"; do
		sed -i "s/^$step$/#$step/" "$0"
	done
}

dots() {
	arch-chroot /mnt su "$USER_NAME" -c "cd \$HOME ; git --git-dir=\$HOME/repos/dots --work-tree=\$HOME $*"
}

doas_prompt() {
	cat <<- EOF
		expect <<- DOAS
			set timeout -1
			spawn $@
			expect {
				"doas ($USER_NAME@archlinux) password: " {
					send "$USER_PASSWORD\r"
					exp_continue
				}
			}
		DOAS
	EOF
}

# ========== Core ==========

check_variables() {
	valid_username=$(echo "$USER_NAME" | grep "^[a-z_][a-z0-9_-]*$" || echo "")
	keymaps=$(localectl list-keymaps | grep -E "^$KEYMAP$" || echo "")
	locales=$(grep -P "#[\S@]" /etc/locale.gen | sed -e "s/#//g" | cut -d " " -f 1 | grep "^$LOCALE$" || echo "")
	timezones=$(timedatectl list-timezones | grep -E "^$TIMEZONE$" || echo "")

	if [ -z "$timezones" ]; then
		infobox "The timezone is invalid, check all valid timezones with the alias: 'get-timezones'"
		exit 1
	elif [ -z "$locales" ]; then
		infobox "The locale is invalid, check all valid locales with the alias: 'get-locales'"
		exit 1
	elif [ -z "$keymaps" ]; then
		infobox "The keyboard layout is invalid, check all valid keyboard layouts with the alias: 'get-keymaps'"
		exit 1
	elif [ -z "$valid_username" ]; then
		infobox "Your username is invalid, remember to only use alfanumeric characters, and the first character MUST be a letter"
		exit 1
	elif [ -z "$LUKS_PARTITION_NAME" ] || [ -z "$HOSTNAME" ]; then
		infobox "The LUKS partition name and/or hostname are undefined, check your configuration variables at the top of the 'arsh' file"
		exit 1
	fi

	infobox "Fetching Arch mirror countries with reflector"
	mirror_list=$(reflector --list-countries | sed -E 's/  +/,/g' | cut -d "," -f 1 | sed 1,2d | grep -E "^$MIRROR_COUNTRIES$" || echo "")

	if [ -n "$MIRROR_COUNTRIES" ] && [ -z "$mirror_list" ]; then
		infobox "One or more mirror countries are invalid, check all valid mirror countries with the alias: 'get-mirror-countries'"
		exit 1
	fi
}

welcome() {
	clear
	echo "${blue}                 _      "
	echo "   __ _ _ __ ___| |__   "
	printf "  / _\` | '__/ __| '_ \  \n"
	echo " | (_| | |_ \__ \ | | | "
	echo "  \__,_|_(_)|___/_| |_| ${normal}"
	echo
	echo "This script will automatically setup an LUKS encrypted Arch Linux installation on your system"
	echo "If you have any doubts about the installation process, i strongly recommend installing this"
	printf "on a virtual machine first, once you start, there's no turning back, the whole process is automated\n\n"
	printf "%sWARNING: This means your whole disk will be wiped, deleting ALL your data%s\n\n" "$bold" "$normal"
	read -rp "Do you wanna start the installation? (y/N) " install
	if echo "$install" | grep -vE "^[yY]$"; then
		exit
	fi
}

create_passwords() {
	while :; do
		password_prompt "ROOT_PASSWORD" "Create the root password: " "Repeat the root password: "
		password_prompt "USER_PASSWORD" "Create your user ($USER_NAME) password: " "Repeat your user ($USER_NAME) password: "
		password_prompt "LUKS_PARTITION_PASSWORD" "Create your LUKS partition ($LUKS_PARTITION_NAME) password: " "Repeat your LUKS partition ($LUKS_PARTITION_NAME) password: "
		printf "\nAre you sure about the passwords specified? The installation begins after this (y/N) "
		read -r confirm_passwords
		echo "$confirm_passwords" | grep -qvE "^[yY]$" || break
	done
}

partitioning() {
	infobox "Creating boot (/dev/sda1), swap (/dev/sda2), and root (/dev/sda3) partitions"
	boot_partition_create="n 1 _ +550M"
	swap_partition_create="n 2 _ +${swap}G"
	root_partition_create="n 3 _ _"

	boot_partition_type="t 1 1"
	swap_partition_type="t 2 19"

	fdisk_instructions="
		g
		$boot_partition_create
		$swap_partition_create
		$root_partition_create
		$boot_partition_type
		$swap_partition_type
		w
	"
	for instruction in $fdisk_instructions; do
		printf "%s\n" "$instruction" | grep -q "_" && printf "\n" || printf "%s\n" "$instruction"
	done | fdisk /dev/sda

	complete_steps partitioning
}

formatting() {
	infobox "Formatting boot partition as FAT32"
	mkfs.fat -F32 $boot_partition

	infobox "Setting up swap partition"
	mkswap $swap_partition
	swapon $swap_partition

	infobox "Setting up LUKS encryption on root partition"
	printf "%s" "$LUKS_PARTITION_PASSWORD" | cryptsetup luksFormat -v $root_partition -d -

	infobox "Opens encrypted root partition in order to format it"
	printf "%s" "$LUKS_PARTITION_PASSWORD" | cryptsetup open $root_partition "$LUKS_PARTITION_NAME" -d -

	infobox "Formats root partition as ext4"
	mkfs.ext4 "/dev/mapper/$LUKS_PARTITION_NAME"

	infobox "Mount root partition to /mnt"
	mount "/dev/mapper/$LUKS_PARTITION_NAME" /mnt

	infobox "Mount boot partition to /mnt/boot"
	mkdir /mnt/boot
	mount $boot_partition /mnt/boot

	complete_steps formatting
}

mirrors() {
	if [ -z "$MIRROR_COUNTRIES" ]; then
		infobox "Fetching the most recently updated generic mirrors"
		reflector --sort age --save /etc/pacman.d/mirrorlist
	else
		infobox "Fetching the most recently updated mirrors from $MIRROR_COUNTRIES"
		reflector --sort age -c "$MIRROR_COUNTRIES" --save /etc/pacman.d/mirrorlist
	fi
}

install_base_packages() {
	infobox "Enabling pacman parallel downloads on arshiso"
	sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf

	infobox "Initialize pacman keyring"
	pacman-key --init

	infobox "Verifying pacman keyring master keys"
	pacman-key --populate archlinux

	infobox "Synchronizing package databases"
	pacman -Sy

	infobox "Installing base system packages: $base_packages"
	pacstrap /mnt $base_packages

	complete_steps install_base_packages
}

generate_filesystem_table() {
	infobox "Generating filesystem table"
	genfstab -U /mnt >> /mnt/etc/fstab

	complete_steps generate_filesystem_table
}

bootloader() {
	sed -i "s/autodetect modconf/autodetect keyboard keymap modconf/" /mnt/etc/mkinitcpio.conf
	sed -i "s/modconf block/modconf block encrypt/" /mnt/etc/mkinitcpio.conf

	arch-chroot /mnt mkinitcpio -p linux

	infobox "Installing GRUB"
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

	infobox "Generating GRUB config file"
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	luks_partition_uuid=$(blkid -o value $root_partition | head -n 1)
	grub_old_string="GRUB_CMDLINE_LINUX=\"\""
	grub_kernel_parameters="cryptdevice=UUID=$luks_partition_uuid:$LUKS_PARTITION_NAME root=/dev/mapper/$LUKS_PARTITION_NAME"
	grub_new_string="GRUB_CMDLINE_LINUX=\"$grub_kernel_parameters\""
	sed -i "s|$grub_old_string|$grub_new_string|" /mnt/etc/default/grub
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

	complete_steps bootloader
}

keymap() {
	infobox "Saving persistent keyboard layout configuration"
	echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

	complete_steps keymap
}

timezone() {
	infobox "Setting timezone"
	ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

	infobox "Setting hardware clock from system clock"
	arch-chroot /mnt hwclock --systohc

	complete_steps timezone
}

locales() {
	infobox "Generating locales for '$LOCALE'"
	sed -i "s/#${LOCALE}/${LOCALE}/" /mnt/etc/locale.gen
	arch-chroot /mnt dash <<- EOF
		locale-gen
	EOF

	infobox "Saving locales configuration on '/etc/locale.conf'"
	echo "LANG=$LOCALE" | cut -d " " -f 1 > /mnt/etc/locale.conf

	complete_steps locales
}

root_password() {
	infobox "Setting root password"
	arch-chroot /mnt dash <<- EOF
		printf "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
	EOF

	complete_steps root_password
}

create_user() {
	infobox "Creating non-root user '$USER_NAME'"
	arch-chroot /mnt useradd -mG wheel,video,storage "$USER_NAME"
	arch-chroot /mnt dash <<- EOF
		printf "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USER_NAME
	EOF

	complete_steps create_user check_variables
}

hostname() {
	infobox "Setting hostname"
	echo "$HOSTNAME" > /mnt/etc/hostname

	infobox "Setting hosts file"
	cat <<- EOF /mnt/etc/hosts
		127.0.0.1     localhost
		::1           localhost
		127.0.0.1     ${HOSTNAME}.localdomain ${HOSTNAME}
	EOF

	complete_steps hostname
}

install_rice_packages() {
	infobox "Enabling pacman parallel downloads on new system"
	sed -i 's/#ParallelDownloads/ParallelDownloads/g' /mnt/etc/pacman.conf

	infobox "Synchronizing package databases"
	arch-chroot /mnt pacman -Sy

	infobox "Installing rice packages"
	arch-chroot /mnt pacman --noconfirm -S $rice_packages

	infobox "Removing 'sudo' from 'base-devel'"
	arch-chroot /mnt pacman --noconfirm -R sudo

	complete_steps install_rice_packages
}

setup_zsh() {
	infobox "Setting zsh as the default interactive shell"
	arch-chroot /mnt su "$USER_NAME" <<- EOF
		expect <<- PASS
			spawn chsh -s /usr/bin/zsh
			expect "Password: "
			send "$USER_PASSWORD\r"
			expect eof
		PASS
	EOF

	infobox "Removing bash files at /home/$USER_NAME"
	rm /mnt/home/$USER_NAME/.bash*

	complete_steps setup_zsh
}

doas_config() {
	infobox "Giving super-user permissions to '$USER_NAME'"
	echo "permit $USER_NAME as root" > /mnt/etc/doas.conf

	complete_steps doas_config
}

install_paru() {
	infobox "Installing 'paru' AUR helper"
	arch-chroot /mnt su "$USER_NAME" <<- EOF
		git clone https://aur.archlinux.org/paru-bin.git ~/repos/paru-bin
		cd ~/repos/paru-bin

		expect <<- DOAS
			spawn makepkg --noconfirm -si
			expect "Password: "
			send "$ROOT_PASSWORD\r"
			expect eof
		DOAS
	EOF

	complete_steps install_paru
}

install_aur_packages() {
	infobox "Installing AUR rice packages"
	# Sourcing '/etc/profile' is needed due to pod2man (/usr/bin/core_perl/pod2man) being added in
	# '/etc/profile.d/perlbin.sh' which is only sourced by a login shell
	arch-chroot /mnt su "$USER_NAME" <<- EOF
		. /etc/profile
		$(doas_prompt paru --sudo doas --sudoflags -- --removemake --cleanafter --noconfirm -S $aur_packages)
	EOF

	complete_steps install_aur_packages
}

deploy_dotfiles() {
	infobox "Cloning dotfiles repository on '/home/$USER_NAME/repos/dots'"
	arch-chroot /mnt su "$USER_NAME" -c "git clone --bare https://github.com/henriquehbr/dots \$HOME/repos/dots"

	infobox "Removing possibly conflicting dotfiles submodules"
	arch-chroot /mnt rm -rf $(dots submodule--helper list | awk '{print $4}')

	infobox "Deploying dotfiles"
	dots checkout -f

	infobox "Deploying dotfiles submodules (st)"
	dots submodule update --init --recursive

	complete_steps deploy_dotfiles
}

install_st() {
	infobox "Installing st (simple terminal) from source"
	arch-chroot /mnt su "$USER_NAME" <<- EOF
		$(doas_prompt doas -- make -C "\$HOME/.config/st" clean install)
	EOF

	complete_steps install_st
}

post_install() {
	infobox "Enabling NetworkManager service"
	arch-chroot /mnt systemctl enable NetworkManager

	infobox "Syncing local time with network time"
	arch-chroot /mnt systemctl enable systemd-timesyncd

	infobox "Unmounting root partition from /mnt"
	umount -l /mnt

	complete_steps post_install
}

# When each one of these steps are completed, they'll automatically be commented out to avoid repetitions
# (which certainly won't work, or might even break the current installation) on subsequent executions

clear

check_variables
welcome
create_passwords
partitioning
formatting
mirrors
install_base_packages
generate_filesystem_table
bootloader
keymap
timezone
locales
root_password
create_user
hostname
install_rice_packages
setup_zsh
doas_config
install_paru
install_aur_packages
deploy_dotfiles
install_st
post_install

infobox "Installation finished! you might remove the installation media and reboot now"
