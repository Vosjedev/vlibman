#!/usr/bin/env bash

##################
# 'ui' functions #
##################

# print and color

    function c {
        # color
        local c="\e["
        while [[ "$#" -gt 1 ]]; do
            case "$1" in
                b) c+='1;';;
                r) c+='0;';;
                i) c+='7;';;
                bg) _background=true
            esac
            shift
        done
        case "$1" in
            r) c+='31m';;
            g) c+='32m';;
            y) c+='33m';;
            b) c+='34m';;
            p) c+='35m';;
            c) c+='36m';;
            w) c+='37m';;
            n) c+='38m';;
            R) c+='0m'
        esac
        echo -ne "$c" 
    }

    function warn {
        echo -e "[$(c y)warn$(c R)]" "$@"
    }
    function err {
        echo -e "[$(c r)err $(c R)]" "$@"
    }
    function info {
        echo -e "[$(c b)info$(c R)]" "$@"
    }

# control

    function quit {
        case "$1" in
            ''|0) info 'exit'; exit 0;;
            * ) warn "exit (code $1)"; exit "$1"
        esac
    }

# menus

    function ask {
        while true; do
            if [[ "$2" == '' ]]; then
                echo "$1"
            else
                "$2" "$1"
            fi
            read -rn1 -p "[$(c g)y$(c R)/$(c r)n$(c R) ]? " yn
            echo
            case "$yn" in
                y|Y) return 0;;
                n|N) return 1;;
                *) err "Invalid. Enter y for yes or n for no."
            esac
        done
    }

    function checklist {
        tput civis >/dev/stderr
        stty -echo
        local sel=1
        local cnt=1
        local line=1
        # local q="*"
        # uncheck all
        declare -A checked
        for i in "$@"; do
            checked[$i]='n'
        done
        # free space for checklist
        echo -ne '\n\n\n\n\n\n\n\n' >/dev/stderr
        tput cuu 8 >/dev/stderr
        echo '==========================' >/dev/stderr
        # shellcheck disable=2155
        local cline="$(curpos l)"
        local height=$((LINES-cline-2))
        tput sc >/dev/stderr
        while true; do
            cnt=1
            for i in "$@"; do
                if [[ $cnt -ge $line ]] && [[ $cnt -le $((line+height)) ]]; then
                    if [[ ${checked[$i]} == y ]]
                    then echo -n "[$(c g)x$(c R)] " >/dev/stderr
                    else echo -n "[ ] " >/dev/stderr
                    fi
                    [[ $cnt == "$sel" ]] && c i n >/dev/stderr
                    echo -n "$i$(c R)" >/dev/stderr
                    eval "printf -- ' %.0s' {1..$((COLUMNS-${#i}-4))}"
                    echo >/dev/stderr
                fi
                ((cnt++))
            done
            echo -n '==========================' >/dev/stderr
            IFS=$'\t' read -rsn1 in
            case "$in" in
                $'\e')
                    read -rsn1 in
                    case "$in" in
                        '[' )
                            read -rsn1 in
                            case "$in" in
                                A) ((sel--)); [[ $sel -lt 1 ]] && sel=1;;
                                B) ((sel++)); [[ $sel -gt "$#" ]] && sel=$#;;
                            esac
                        ;;
                    esac
                ;;
                ' ')
                    if [[ "${checked[${@:$sel:1}]}" == y ]]; then
                        checked[${@:$sel:1}]=n
                    else
                        checked[${@:$sel:1}]=y
                    fi
                ;;
                '/')
                echo -ne '\r                           \r'
                ;;
                q|'') break;;
            esac
            if [[ $sel -lt $line ]]; then
                line=$sel
            elif [[ $sel -gt $((line+height)) ]]; then
                line=$((sel-height))
            fi
            tput rc >/dev/stderr
        done
        tput cnorm >/dev/stderr
        for i in "$@"; do
            if [[ "${checked[$i]}" == y ]]; then
                echo -n "$i "
            fi
        done
        stty echo
    }

#

###################
# random funcions #
###################

# true randomness

    function fcat {
        : "
        a build-in cat for
        fcat <<< EOF
        text, text
        EOF
        type-situations.
        "
        while read -r line; do echo "$line"; done
    }

    function axel-dl {
        # very trimmed version of https://github.com/Vosjedev/cmd-tools/blob/main/dl
        tput civis
        eval "axel -o '$2' '$1'" 2>&1 | {
            while read -r line; do
                pers="$(echo "$line" | cut -d ']' -f '1' -s | cut -c '3-4')"
                pers="${pers// /}"
                if [[ "$pers" =~ ^[0-9]+$ ]]
                then [[ "$pers" == 00 ]] && pers=100
                    dispers="[$pers%] "
                    cols=$(($(tput cols)-${#dispers}-2))

                    infoline="$(echo "$line" | cut -d '[' -f '3,4' -s)"
                    # infoline="${infoline// /}"
                    infoline=" [${infoline}"
                    cols=$((cols-${#infoline}))

                    out="$dispers"
                    ch="$(echo "$cols*($pers/100)" | bc -l | cut -d . -f 1)"

                    out="$out$(eval "printf '#%.0s' {1..$ch}")"
                    out="$out$(eval "printf '=%.0s' {1..$((cols-ch))}")"
                    out="$out$infoline"
                    echo -ne "${out}"
                    echo -ne "\r"
                elif [[ "$line" == '' ]]
                then :
                else :
                fi
            done
        } 
        tput cnorm
    }

    function download {
        for dl in 'axel' 'curl' 'wget'; do command -v "$dl">/dev/null && { fnddl=true; break; }; done
        [[ "$fnddl" == true ]] || {
            warn "No good downloader found... Please make sure one of these is installed:"
            warn "axel, curl, wget"
        }
        case "$dl" in
            curl) curl -# -o "$2" -- "$1";;
            axel) axel-dl "$1" "$2";;
            wget) wget -o "$2" "$1"
        esac
    }

# control

    # shellcheck disable=2120
    function quit {
        case "$1" in
            ''|0) info 'exit'; exit 0;;
            * ) warn "exit (code $1)"; exit "$1"
        esac
    }

#


##########
# libman #
##########

function refresh {
    warn "Not implemented yet"
}

function pull {
    warn "Not implemented yet"
}

function install {
    warn "Not implemented yet"
}


###############
# CLI parsing #
###############

for cmd in "cut" "grep"
do command -v "$cmd" >/dev/null || {
    warn "Command $cmd not found! Please install and try again."
    quit 2
}
done

# help
function getHelp {
 echo "usage: vlibman [-g] [-h|--help] action [action args:]
     -g : global: operate on a global instance instead of first instance found in tree.
     -h : help  : display this help
 "
 exit
}

for arg in "$@"; do [[ "$arg" == '--help' ]] && getHelp; [[ "$arg" != "-"* ]] && break; done

# parse opts
while getopts "gh" opt; do
    case "$opt" in
        h) getHelp;;
        g)
            if ! [[ -d ~/.local/share/vlibman ]]; then
                if ask "A global instance was not found, do you want to create one in ~/.local/share/vlibman?"; then
                    mkdir -p ~/.local/share/vlibman
                else
                    err "Cannot operate on non-existent instance."
                    quit 1
                fi
            fi
            cd ~/.local/share/vlibman || { err "could not cd into global instance."; quit 2;}
        ;;
        *) warn "invalid opt $opt"; getHelp;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# parse actions

pwd="$PWD"
while ! [[ -d '.vlibman' ]]; do
    cd ..
    [[ "$PWD" == '/' ]] && {
        cd "$pwd" || { err "Could not cd back to '$pwd'. Does the folder still exist?"; quit 2; }
        warn "An instance of vlibman was not found in this directory or any of the directories above."
        if ask "Do you want to create one in '$pwd'?"; then
            install
        else
            err "No vlibman instance found, and user refused to create one."
            info "If you were trying to access your global 'user' instance, use the -g flag."
            quit 1
        fi
    }
done
cd '.vlibman' || {
    err "Could not cd into $PWD/.vlibman, even though this folder is present."
    quit 2
}

action="$1"
shift
case "$action" in
    'refresh') refresh_cache;;
    'pull') pull "$@";;
esac


