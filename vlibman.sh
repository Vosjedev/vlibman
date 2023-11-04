#!/usr/bin/env bash

LINES="$(tput lines)"
COLUMNS="$(tput cols)"

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
                    eval "printf -- ' %.0s' {1..$((COLUMNS-${#i}-4))}" >/dev/stderr
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
        echo ''>/dev/stderr
        stty echo
    }

    function radiolist {
        tput civis >/dev/stderr
        stty -echo
        local sel=1
        local cnt=1
        local line=1
        # local q="*"
        # uncheck all
        menu=false
        if [[ "$1" == '--menu' ]]; then
            menu=true; shift
        fi
        local check=1
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
                    if "$menu"; then
                        if [[ $cnt == "$check" ]]
                        then echo -n " $(c g)>$(c R) " >/dev/stderr
                        else echo -n "   " >/dev/stderr
                        fi
                    else
                        if [[ $cnt == "$check" ]]
                        then echo -n "[$(c g)x$(c R)] " >/dev/stderr
                        else echo -n "[ ] " >/dev/stderr
                        fi
                    fi
                    [[ $cnt == "$sel" ]] && c i n >/dev/stderr
                    echo -n "$i$(c R)" >/dev/stderr
                    eval "printf -- ' %.0s' {1..$((COLUMNS-${#i}-4))}" >/dev/stderr
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
                    check=$sel
                ;;
                '/')
                echo -ne '\r                           \r' >/dev/stderr
                ;;
                q|'') break;;
            esac
            if [[ $sel -lt $line ]]; then
                line=$sel
            elif [[ $sel -gt $((line+height)) ]]; then
                line=$((sel-height))
            fi
            "$menu" && check="$sel"
            tput rc >/dev/stderr
        done
        tput cnorm >/dev/stderr
        eval "echo \"\$$check\""
        echo ''>/dev/stderr
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
    function lcat {
        : "
        a build-in cat for reading files without coreutils dep.
        "
        while read -r line; do echo "$line"; done < "$1"
    }

    function axel-dl {
        # very trimmed version of https://github.com/Vosjedev/cmd-tools/blob/main/dl
        tput civis
        { eval "axel -a -o '$2' '$1'" 2>&1 && echo "[100%] [done!] [$infoline"; } | {
            while read -r line; do
                pers="$(echo "$line" | cut -d '%' -f '1' -s | cut -d '[' -f 2)"
                pers="${pers// /}"
                if [[ "$pers" =~ ^[0-9]+$ ]]
                then
                    dispers="[$pers%] "
                    cols=$(($(tput cols)-${#dispers}-2))

                    infoline="$(echo "$line" | cut -d '[' -f '4,5')"
                    # infoline="${infoline// /}"
                    infoline=" [${infoline}"
                    cols=$((cols-${#infoline}))

                    out="$dispers"
                    ch="$(echo "$cols*($pers/100)" | bc -l | cut -d . -f 1)"

                    out="$out$(eval "printf '#%.0s' {0..$ch}")"
                    out="$out$(eval "printf '=%.0s' {0..$((cols-ch))}")"
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
        echo
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

    function curpos {
        read -rsdR -p $'\e[6n' curpos
        curpos="${curpos:2}"
        IFS=';' read -r l c <<< "$curpos"
        case "$1" in
            c|col|column) echo -n "$c";;
            l|line) echo -n "$l"
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
    info "Getting lates liblist.txt..."
    download "https://vosjedev.pii.at/vlibman/liblist.txt" "liblist.tmp" || {
        err "Download failed."
        rm liblist.tmp
        quit 2
    }
    info "Replacing..."
    rm liblist.txt
    mv liblist.tmp liblist.txt
    info "Done."
}

function pull {
    info "Getting libs..."
    cd ..
    for lib in "$@"; do
        case "$lib" in
            "id="*) IFS='=' read -r of libid of<<<"$lib"; ;;
            *)  q="$lib"
                results=()
                while IFS=$'\t' read -r id name url desc lang ext version of; do # get all libs with this name
                    if [[ "$name" == "$q" ]] || [[ "$name.$lang" == "$q" ]]|| [[ "$name.$ext" == "$q" ]]; then
                        results+=( "$id -- $lang, $desc" )
                    fi
                done < <(tail -n +2 .vlibman/liblist.txt)
                if [[ "${#results[*]}" -gt 1 ]]; then
                    libid="$(radiolist --menu "${results[@]}" | cut -d ' ' -f 1)" # ask user what id they want
                else libid="$(echo "${results[0]}" | cut -d ' ' -f 1)"
                fi
                ;;
        esac
        url="$(tail -n +2 .vlibman/liblist.txt | cut -f 1,3 | grep -G '^'"$libid"'.*' | cut -f 2)"
        ext="$(tail -n +2 .vlibman/liblist.txt | cut -f 1,5 | grep -G '^'"$libid"'.*' | cut -f 2)"
        name="$(tail -n +2 .vlibman/liblist.txt | cut -f 1,2 | grep -G '^'"$libid"'.*' | cut -f 2)"
        info "pulling $libid from $url"
        download "$url" "$name.$ext"
    done
}

function search {
    function table {
        column -t -s $'\t'
    }
    column --help | grep -- '--separator' >/dev/null || {
        err "This version of columns does not support the --seperator argument. Search may not output correctly"
        function table { cat; }
        }

    case "$1" in
        'lang') q="$2"
            {
                echo -e "#name\t#description\t#languages"
                # shellcheck disable=2034
                tail -n +2 liblist.txt |\
                while IFS=$'\t' read -r id name url desc lang ext version of; do
                    if [[ "$lang" == *"$q"* ]]; then
                        echo -e "$name\t$desc\t$lang"
                    fi
                done
            } | table
        ;;
        'id') q="$2"; cat <(head -n1 liblist.txt | cut -f 1,2,4,5) <(tail -n +2 liblist.txt | cut -f 1,2,4,5 | grep -G '^'"$q"'.*') | table
        ;;
        *)
            q="$1"; cat <(head -n1 liblist.txt | cut -f 2,4,5) <(tail -n +2 liblist.txt | cut -f 1,2,4,5 | grep "$q" | cut -f 2,3,4) | table
    esac
}

function install {
    {
        function cleanup {
            info "Aborted."
            info "Cleaning up..."
            cd ..
            rm -vrf .vlibman
            info "Done."
            warn "Quit reason: $1."
            quit 2
        }
        trap "cleanup 'User interupt'" INT
        mkdir .vlibman
        cd .vlibman
        info "Downloading version info..."
        download "https://vosjedev.pii.at/vlibman/images/versions.txt" versions.txt # get versions file
        vinfo="$(lcat versions.txt)" # read versions file
        info "Please choose your version."
        info "If you aren't sure, pick the first entry."
        # shellcheck disable=2086
        image="$(radiolist --menu $vinfo)" # prompt user which version they want
        info "Downloading the vlibman image $image..."
        download "https://vosjedev.pii.at/vlibman/images/$image.tar.gz" "$image.tar.gz" # get image
        download "https://vosjedev.pii.at/vlibman/images/$image.checksum" "$image.checksum" # get checksum
        info "Done. Checking checksums..."
        remoteChecksum="$(lcat "$image.checksum")" # read remote checksum
        localChecksum="$(sha256sum "$image.tar.gz")" # generate local checksum
        if ! [[ "$localChecksum" == "$remoteChecksum" ]]; then # if not the same
            while read -rst 0.1; do :; done # remove all keypresses from scripts, so accidental approval is less likely
            err "Local checksum and remote checksum do not match!"
            info "local checksum : $localChecksum"
            info "remote checksum: $remoteChecksum"
            warn "Installation could result in a broken install if continued."
            warn "If you decide to proceed, do so with caution."
            warn "Please don't fire a bug report if issues occur."
            if ! ask "Continue installation?"; then
                cleanup "Bad checksums"
            else
                warn "Continuing with bad files."
            fi
        else info "Checksums valid."
        fi
        info "Extracting image..."
        tar -xvzf "$image.tar.gz"
        info "Done extracting."

        info "Use vlibman refresh to refresh the libraries list,"
        info "or vlibman pull <lib> to pull a lib."

    } || { err "An error occured while installing."; quit 2; }
}


###############
# CLI parsing #
###############

# check dependencies
for cmd in "cut" "grep" "sha256sum" "mkdir" "cp" "mv" "rm" "tar" "head" "tail" "cat"
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

    actions:
     init    : Does nothing, but usefull to install only.
     pull    : Unimplemented.
     refresh : Unimplemented.
     reinit  : deletes .vlibman directory, and reruns installation.
    
    error codes:
     0: no errors
     1: user error
     2: system error
     anything else: please make a bug report, that shouldn't happen!

    If no valid .vlibman directory was found in the current directory or any of its parent, the user is prompted if vlibman should install one.
 "
 exit
}

# check if --help passed
for arg in "$@"; do [[ "$arg" == '--help' ]] && getHelp; [[ "$arg" != "-"* ]] && break; done

# parse opts
local=false
while getopts "glh" opt; do
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
        l)
            local=true
        ;;
        *) warn "invalid opt $opt"; getHelp;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# parse actions

# find .vlibman folder
pwd="$PWD"
while ! [[ -d '.vlibman' ]]; do
    cd ..
    [[ "$PWD" == '/' ]] && { # no folder found, prompt user for new one
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
cd '.vlibman' || { # enter .vlibman folder
    err "Could not cd into $PWD/.vlibman, even though this folder is present."
    quit 2
}

if ! "$local" && ! [[ "$1" == reinit ]]; then
    bash vlibman.sh -l "$@"
    exit $?
fi

# determine action
action="$1"
shift
case "$action" in
    'refresh') refresh;;
    'pull') pull "$@";;
    'search') search "$@";;
    'init') :;;
    'reinit')
        if ask "Do you want to delete and reinstall the .vlibman directory?"; then
            cd ..
            warn "Removing..."
            rm -vrf .vlibman
            info "Done."
            install
        fi
        ;;
    '') quit 0;;
    *) err "Unknown action."; quit 1
esac


