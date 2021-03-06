#==============================================================
# => Bash Aliases
#
# Shorten commands, add commands you frequently mistype, add
# helpful little shortcuts for things, and finally add
# usefull automatic default parameters to commands you use
# already
#==============================================================

# Ask before over-writting a file
alias mv='mv -i'

# Ask before deleting a file, and automatically make it recursive
alias rm='rm -Ri'

# Ask before over-writting a file and recursively copy by default
alias cp='cp -iR'

# We want free disc space in human readable output, trust me
alias df='df -h'

if [ -z "$(echo "$OPERATING_SYSTEM" | grep -E 'OSX.*')" ]; then
    # Show me all files and info about them
    alias ll='ls -lh --color'

    # Show me all files, including .dotfiles, and all info about them
    alias la='ls -lha --color'

    # Show me colors for regualr ls too
    alias ls='ls --color'
else
     # Show me all files and info about them
    alias ll='ls -lh'

    # Show me all files, including .dotfiles, and all info about them
    alias la='ls -lha'


fi

# Automatically make directories recursivly
alias mkdir='mkdir -p'

# Vim misspellings nuff' said
alias cim='vim'
alias bim='vim'
alias fim='vim'
alias gim='vim'
alias vi='vim'

# easily move up one directory
alias ..='cd ..'

# easily move up two directories
alias ....='cd ../..'

# easy mysql connection just tack on a -h
alias sql='mysql -umysql -pmysql'

# easy mysql dump just tack on a -h
alias sqld='mysqldump -umysql -pmysql --routines --single-transaction'

# share history between terminal sessions
alias he="history -a" # export history
alias hi="history -n" # import history

# Get your current public IP
alias public_ip="curl icanhazip.com"

# Auto install web dependancies
alias deps_install="composer install;npm install;bower install"
alias deps_update="composer update;npm update;bower update"

# easier dotfile installation
alias dot="source $HOME/.bash_profile"

# use rlwrap if we have it
telnet() {
    if is_installed "rlwrap"; then
        rlwrap telnet "$@"
    else
        telnet "$@"
    fi
}

# use multitail if we have it
tail() {
    if is_installed "multitail"; then
        multitail "$@"
    else
        tail -f "$@"
    fi
}


