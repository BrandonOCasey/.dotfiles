#==============================================================
# => Bash Functions
#
# Aliases for commonly used things that are too big to put into
# an alias and functions that do special things that you find
# yourself repeating all the time
#==============================================================


big_files() {
    local folder="."
    if [ -n "$1" ]; then
        folder="$1"
    fi

    while read -r file; do
        du -h "$file"
    done <<< "$(find "$folder" -size +1M)" | sort -n
}

tar_folders() {
    GZIP=-9
    local folder="./*"
    if [ -n "$1" ]; then
        folder="$1"
    fi

    for file in $folder; do
        if [ -d "$file" ]; then
            tar_name="$(echo "$file" | sed 's~./~~').tar.gz"
            echo "Creating $tar_name in current directory"
            tar czf "$tar_name" "$file"
        fi
    done
}

# http://stackoverflow.com/a/13322667
local_ip() {
    local _ip _line
    while IFS=$': \t' read -a _line ;do
        [ -z "${_line%inet}" ] &&
           _ip=${_line[${#_line[1]}>4?1:2]} &&
           [ "${_ip#127.0.0.1}" ] && echo $_ip && return 0
      done <<< "$(LANG=C /sbin/ifconfig)"
    local _ip _myip _line _nl=$'\n'
}


centos_obsolete_libs() {
    yum list 2> /dev/null | grep -E -- "^lib" | grep installed | awk -F" " '{print $1}' | sed -e 's_\(.*\)\.i386_\1_' -e 's_[0-9]*\.[0-9]*__' | uniq -c | sed 's_^\s*__' | grep -E -- ^[2-9][2-9]* | sed 's_[0-9]* __'
}



#--------------------------------------------------------------
#
# Find/Replace
#
#--------------------------------------------------------------

#
# gg_replace
#
# Find and replace recursivly from the current directory
#
gg_replace() {
    if [ "$#" -lt "2" ]; then
        echo '    Usage:'
        echo '        gg_replace term replacement'
        echo
        echo '    Example:'
        echo '        gg_replace cappuchino cappuccino'
        echo
        return 1
    fi

    find=$1; shift
    replace=$1; shift

    ORIG_GLOBIGNORE=$GLOBIGNORE
    GLOBIGNORE=*.*

    if [ "$#" = "0" ]; then
        set -- ' ' "$@"
    fi

    while [ "$#" -gt "0" ]; do
        for file in `grep -lR "$find" ./`; do
            echo "Doing find replace in $file"
            sed -e "s/$find/$replace/g" | tee $file > /dev/null
        done
        shift
    done

    GLOBIGNORE=$ORIG_GLOBIGNORE
}





todos() {
    local excludes=".svn"
    excludes+="\|.git"
    excludes+="\|$DOTFILES_ROOT/dist/vim/vim.symlink/bundle"
    excludes+="\|$DOTFILES_ROOT/README.md"
    excludes+="\|$DOT_TMP_ROOT"
    excludes+="\|$DOT_BACK_ROOT"
    for var in "$@"; do
        excludes+="\|$var"
    done

    # we have T\ODO so that we will never find this function in our list
    local grep_search='T\ODO:?'
    grep -RHEli "$grep_search" "$(pwd)"/* | grep -v "$excludes" |  while read -r file; do
        matches=$(grep -nEi "$grep_search" "$file" | grep -v "t\odos() {")
        if [ -n "$matches" ]; then
            echo "$file" | grep --color "$file"
            echo "$matches" |  while read -r  match; do
                echo "    $match"
            done
            echo
        fi
    done
}


rm_empty() {
    local search_in="./*"
    if [ -n "$1" ]; then
        search_in="$1"
    fi

    for i in "$search_in"; do
        if [ ! -s "$i" ];then
            rm -rf "$i"
        fi
    done
}


#--------------------------------------------------------------
#
# Print Commands
#
#--------------------------------------------------------------

aa_256() {
    ( x=`tput op` y=`printf %$((${COLUMNS}-6))s`;for i in {0..256};do o=00$i;echo -e ${o:${#o}-3:3} `tput setaf $i;tput setab $i`${y// /=}$x;done; )
}

print_json() {
    if [ "$#" -ne "1" ]; then
        echo 'Usage:'
        echo "  print_json 'json' "
        echo
        echo 'Example:'
        echo " print_json '{\"foo\": \"lorem\", \"bar\": \"ipsum\"}' "
        echo
        return 1
    fi
    echo "$1" | python -m json.tool
}

print_xml() {
    if [ "$#" -ne "1" ]; then
        echo 'Usage:'
        echo "  print_json 'xml' "
        echo
        echo 'Example:'
        echo " print_json '<root><foo a=\"b\">lorem</foo><bar value=\"ipsum\" /></root>' "
        echo
        return 1
    fi

    # Rmove invalid characters between tags
    echo "$1" | sed -e 's/>#[0-9]*</></g' | xmllint --format -
}


#--------------------------------------------------------------
#
# Source Control Commands
#
#--------------------------------------------------------------

svn_up_all() {

    local search_in="*/"
    if [ -n "$1" ]; then
        search_in="$1"
    fi
    for directory in $(ls -d "$search_in"); do
        if [ -d "$directory/.svn" ]; then
            svn up "$directory"
        fi
    done
}

# Remove /browser/, query params, and replace /trac/ with /svn/
cow() {
    if [ "$#" -ne "1" ]; then
        echo 'Usage:'
        echo '  cow https_link optional_location'
        echo
        echo 'Example:'
        echo '  cow https://svn.com/trac/things?rev=999'
        echo
        return 1
    fi
    link="$1"; shift
    dir="$1"; shift

    link=$(echo "$link" | sed -e 's~\/trac\/~\/svn\/~')
    link=$(echo "$link" | sed -e 's~/browser/~/~')
    link=$(echo "$link" | sed -e 's~\?.*$~~')

    svn co $link $dir

}


gcommit() {
    if [ "$#" -ne "1" ]; then
        echo 'Usage:'
        echo "  gcommit '<commit info>'"
        echo
        echo "Example:"
        echo "  gcommit 'added some logging things'"
        echo
        return 1
    fi
    git add --all
    git commit -a -m "$1"
    git push
}


#--------------------------------------------------------------
#
# Binary Commands
#
#--------------------------------------------------------------

script_forever() {
    if [ "$#" != "2" ]; then
        echo '  Usage:'
        echo '    script_forever <script_path> <log>'
        echo
        echo '  Example:'
        echo '    script_forever ./test.sh ./thing.log'
        echo
        return 1
    fi

    local program="$1"; shift
    local log="$1"; shift

    if [ ! -x "$program" ]; then
        echo "File $program does not exist, or is not executable"
        return 1
    fi
    program="$( fullpath "$program" )"
    log="$( fullpath "$log" )"

    ($program 2>&1 > "$log" &)
    local pid="$(getpid "$program")"
    echo "Successfully started $program logging to $log and pid $pid"
}

command_forever() {
    if [ "$#" -lt "2" ]; then
        echo '  Usage:'
        echo '    command_forever <command> <log> <delay optional>'
        echo
        echo '  Example:'
        echo "    command_forever 'echo \"hello \$i\"' /tmp/test.log '1m'"
        echo
        return 1
    fi

    local command_to_run="$1"; shift
    local log="$1"; shift
    local delay=""
    if [ -n "$1" ]; then
        delay="$1"; shift
    fi
    log="$( fullpath "$log" )"

    local execute="#!/usr/bin/env bash\n\n"
    execute+="trap \"rm -f \$0; exit\" SIGTERM SIGINT\n"
    execute+="i=0\n"
    execute+="while [ \"1\" ]; do\n"
    execute+="i=\$((i+1))\n"
    if [ -n "$delay" ]; then
        execute+="    sleep $delay\n"
    fi
    execute+="    $command_to_run\n"
    execute+="done\n"

    local program="/tmp/${RANDOM}.sh"
    printf "$execute" > "$program"
    chmod +x "$program"

    ("$program" 2>&1 > "$log" &)

    local pid="$(getpid "$program")"
    if [ -z "$pid" ]; then
        echo "Failed to run your command, perhaps it has a syntax error?"
    fi
    echo "Started $program with log $log and pid $pid, it will be killed upon exit"
}

getpid() {
    if [ "$#" -lt "1" ]; then
        echo '  Usage:'
        echo '    getpid <search>'
        echo
        echo '  Example:'
        echo "    getpid '/tmp/'"
        echo
        return 1
    fi
    echo "$(ps aux | grep "$1" | grep -v "grep $1" | awk '{print $2}' | xargs)"
}

nkill() {
    if [ "$#" -lt "1" ]; then
        echo '  Usage:'
        echo '    nkill <process_name> ...'
        echo
        echo '  Example:'
        echo '    nkill httpd ssh-agent'
        echo
        return 1
    fi

    pgrep -fl "$@"
    if [ "$?" = "1" ]; then
        echo 'No processes match'
        return 1
    fi
    echo 'Hit [Enter] to pkill, [Ctrl+C] to abort'
    read && pkill -f "$@"
}


watch_process() {
    if [ "$#" -eq "0" ]; then
        echo 'Usage:'
        echo '  watch_process name name ...'
        echo
        echo 'Example:'
        echo '  watch_process httpd'
        echo
        return 1
    fi
    ps aux | grep -v grep | grep --color "$@"
}


m_valgrind() {
    if ! is_installed "valgrind"; then
        echo "valgrind is not installed"
    fi

    if [ "$#" -ne "2" ]; then
        echo 'Usage:'
        echo '  m_valgrind log_output binary'
        echo
        echo 'Example:'
        echo '  m_valgrind /tmp/http_valgrind.log httpd'
        echo
        return 1
    fi
    sudo valgrind --leak-check=full --show-reachable=yes --log-file="$1" --trace-redir=yes -v "$2"
}

_bin_cmd() {
    local run_cmd type_cmd init_scripts
    init_scripts="/etc/init.d/"
    type_cmd="$1"
    shift
    if is_installed "service"; then
        run_cmd="sudo service "
    else
        run_cmd="sudo $init_scripts"
    fi
    while [ "$#" -gt "0" ]; do
        if [ -f "$init_scripts/$1" ]; then
            $run_cmd "$1" $type_cmd
        else
            echo "$1 does not have an init script in $init_scripts"
        fi
        shift
    done
}

bin_restart() {
    if [ "$#" -eq "0" ]; then
        echo 'Usage:'
        echo '  bin_restart bin bin bin'
        echo
        echo 'Example:'
        echo '  bin_restart httpd rsyslog'
        echo
        return 1
    fi
    _bin_cmd "restart" "$@"
}

bin_stop() {
    if [ "$#" -eq "0" ]; then
        echo 'Usage:'
        echo '  bin_stop bin bin bin'
        echo
        echo 'Example:'
        echo '  bin_stop httpd rsyslog'
        echo
        return 1
    fi
    _bin_cmd "stop" "$@"
}

bin_status() {
    if [ "$#" -eq "0" ]; then
        echo 'Usage:'
        echo '  bin_status bin bin bin'
        echo
        echo 'Example:'
        echo '  bin_status httpd rsyslog'
        echo
        return 1
    fi
    _bin_cmd "status" "$@"
}


bin_start() {
    if [ "$#" -eq "0" ]; then
        echo 'Usage:'
        echo '  bin_start bin bin bin'
        echo
        echo 'Example:'
        echo '  bin_start httpd rsyslog'
        q
        echo
        return 1
    fi
    _bin_cmd "start" "$@"
}

_bin_completion() {
    local cur opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(cd /etc/init.d/ ; ls -f ./* | sed 's|\./||')
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
}

tcpd() {
    local pcap="/tmp/${RANDOM}.pcap"
    (sudo nohup /usr/sbin/tcpdump -q -s 0 -i any -w "$pcap" 2>&1 > /dev/null &)
    local pid="$(ps aux | grep $pcap | grep -v grep | awk '{ print $2 }')"


    trap "sudo kill -9 '$pid'; echo; echo '$pcap';trap - SIGINT; trap; return 0" SIGINT
    if [ -z "$pid" ]; then
        echo 'tcpdump failed to start'
        return 1
    fi
    printf 'Hit [Any Key] to kill tcpdump'
    read && sudo kill -9 "$pid"
    sudo chown "$USER":"$USER" "$pcap"
    echo "$pcap"
    trap - SIGINT
    trap
}

complete -F _bin_completion bin_restart bin_start bin_status bin_stop
