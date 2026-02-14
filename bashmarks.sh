# setup file to store bookmarks
if [ -z "$SDIRS" ]; then
    SDIRS="$HOME/.local/share/bashmarks"
fi
touch "$SDIRS"

RED="0;31m"
GREEN="0;33m"

function mark {
    # save current directory to bookmarks
    function bm_s {
        _bookmark_name_valid "$@"
        if [ -z "$exit_message" ]; then
            _purge_line "$SDIRS" "^$1="
            echo "$1=\"$PWD\"" >> "$SDIRS"
        fi
    }

    # jump to bookmark
    function bm_g {
        source "$SDIRS"
        target="$(eval echo \$$1)"

        if [ -d "$target" ]; then
            cd "$target"
        elif [ -z "$target" ]; then
            echo -e "\033[${RED}WARNING: '${1}' bashmark does not exist\033[00m"
        else
            echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
        fi
    }

    # print bookmark
    function bm_p {
        source "$SDIRS"
        eval echo \$$1
    }

    # delete bookmark
    function bm_d {
        _bookmark_name_valid "$@"
        if [ -z "$exit_message" ]; then
            _purge_line "$SDIRS" "^$1="
            unset "$1"
        fi
    }

    # list bookmarks with dirname
    function bm_l {
        while IFS= read -r line; do
            case "$line" in
                ''|\#*) continue ;;
            esac
            key=${line%%=*}
            val=${line#*=}
            printf "\033[0;33m%-20s\033[0m %s\n" "$key" "$val"
        done < "$SDIRS"
    }

    if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ]; then
        echo ''
        echo 'mark <bookmark_name>    - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'mark -s <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'mark -p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'mark -d <bookmark_name> - Deletes the bookmark'
        echo 'mark -l                 - Lists all available bookmarks'
    elif [ "$1" = "-s" ] || [ "$1" = "--save" ]; then
        bm_s ${@:2}
    elif [ "$1" = "-p" ] || [ "$1" = "--print" ]; then
        bm_p ${@:2}
    elif [ "$1" = "-d" ] || [ "$1" = "--delete" ]; then
        bm_d ${@:2}
    elif [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        bm_l
    else
        bm_g "$1"
    fi
}

# list bookmarks without dirname, for autocompletion
function _l {
    while IFS= read -r line; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        echo "${line%%=*}"
    done < "$SDIRS"
}

# validate bookmark name
function _bookmark_name_valid {
    exit_message=""
    if [ -z "$1" ]; then
        exit_message="bookmark name required"
        echo "$exit_message"
    elif [ "$1" != "$(echo "$1" | sed 's/[^A-Za-z0-9_]//g')" ]; then
        exit_message="bookmark name is not valid"
        echo "$exit_message"
    fi
}

# completion command
function _comp {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(_l)" -- "$curw"))
    return 0
}

# ZSH completion command
function _compzsh {
    reply=($(_l))
}

# safe delete line from sdirs
function _purge_line {
    if [ -s "$1" ]; then
        t=$(mktemp -t bashmarks.XXXXXX) || exit 1
        trap "/bin/rm -f -- '$t'" EXIT

        sed "/$2/d" "$1" > "$t"
        /bin/mv "$t" "$1"

        /bin/rm -f -- "$t"
        trap - EXIT
    fi
}

# bind completion command to mark + legacy commands
if [ "$ZSH_VERSION" ]; then
    compctl -K _compzsh mark
    compctl -K _compzsh g
    compctl -K _compzsh p
    compctl -K _compzsh d
else
    shopt -s progcomp
    complete -F _comp mark
    complete -F _comp g
    complete -F _comp p
    complete -F _comp d
fi