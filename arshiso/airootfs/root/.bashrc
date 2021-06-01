alias get-locales="grep -P \"[\S@]\" | sed -e s/#//g | cut -d \" \" -f 1"
alias get-keymaps="localectl list-keymaps"
alias get-mirror-countries="reflector --list-countries"
