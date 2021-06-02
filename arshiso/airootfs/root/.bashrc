alias get-timezones="timedatectl list-timezones"
alias get-locales="grep -P \"#[\S@]\" /etc/locale.gen | sed -e s/#//g | cut -d \" \" -f 1 | more"
alias get-keymaps="localectl list-keymaps | more"
alias get-mirror-countries="reflector --list-countries | more"
