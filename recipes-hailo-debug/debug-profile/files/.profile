# Set aliases
alias ll="ls -ltahF --color=auto"
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Customizing the prompt
PS1='\[\e[1;32m\]\u@\h\e[0m\]:\e[0;33m\w\e[0m\]$ '

# Debug welcome screen
echo -e "\e[33m"
echo "                ___  ___ ___ _   _  ___  "
echo "  | || / | __| |   \| __| _ ) | | |/ __| "
echo "  | __ | |__ \ | |) | _|| _ \ |_| | (_ | " 
echo "  |_||_|_|___/ |___/|___|___/\___/ \___| "

echo -e "\e[33m"
head /etc/os-release -n2 | tail -n1 | awk '{printf "     " $1}'
echo ""
echo -e "\e[31m"


if dmesg | grep -qi error; then
    echo "Errors found:"
    echo "============="
    dmesg | grep -i error | awk '{printf "%d. ", NR; for (i=3; i<=NF; i++) printf "%s ", $i; printf "\n"}'
    echo ""
fi

