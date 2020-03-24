#!/bin/bash
# Nickel Liang (zuodong2@illinois.edu), March 2020.

helper() {
    echo "This script will generate a well-defined Xilinx project structure,"
    echo "and guarantee the other scripts in this utility folder will work" 
    echo "with no modification required."
    echo ""
    echo "Use this script with no arguments to enter interactive mode."
    echo "Use following arguments to custom project creation process:"
    echo "  -a, --all       Generate complete project structure."
    echo "                  Equivalent to -gstv."
    echo "  -g, --git       Copy '.gitignore' file to project directory"
    echo "                  specified by '--path'."
    echo "  -h, --help      Display this helper message."
    echo "  -n, --name      Specify the name of the project."
    echo "  --noreadme      Do not create README.md file in each folder."
    echo "  -p, --path      Specify the path to project directory."
    echo "  -s, --software  Create software directories in both 'source'"
    echo "                  and project directory specified with '--path'."
    echo "  -t, --vitis     Generate Xilinx Vitis project folder and copy"
    echo "                  helper scripts."
    echo "  -v, --vivado    Generate Xilinx Vivado project folder and copy"
    echo "                  helper scripts."
    echo ""
    echo "Exit status:"
    echo "0 if OK,"
    echo "1 if 'getopt' failed,"
    echo "2 if input is invalid."
}

ask() {
    # https://djm.me/ask
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="${C_GREEN}Y${C_NC}/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/${C_RED}N${C_NC}"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do
        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n -e "$1 [$prompt] "
        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty
        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi
        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

check_path() {
    if [ "${2:-}" = "real" ]; then
        mkdir -p "$1"
        if [ "$NO_README" = "n" ]; then
            touch $1README.md
        fi
    else
        ## If directory exist, print with red, otherwise print with green
        if [ -d "$1" ]; then
            echo -e "${C_RED}$1${C_NC}"
        else
            echo -e "${C_GREEN}$1${C_NC}"
        fi
        if [ "$NO_README" = "n" ]; then
            check_file "$1README.md"
        fi
    fi
}

check_file() {
    ## If file exist, print with red, otherwise print with green
    if [ -f "$1" ]; then
        echo -e "${2:-}${C_RED}$1${C_NC}"
    else
        echo -e "${2:-}${C_GREEN}$1${C_NC}"
    fi
}

create_vivado_sh() {
    touch $1
    echo "vivado -mode batch -nojournal -nolog -source $PRJ_NAME.tcl" >> $1
}

create_vivado_tcl() {
    touch $1
    echo "tcl to be written" >> $1
}

## Little Utilities to print color text ##
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_NC='\033[0m' # No Color

## Variables for different options ##
VIVADO=n
VITIS=n 
SOFTWARE=n
GIT=n
PRJ_PATH=".."
PRJ_NAME="project_0"
NO_README=n

## Argument Parser ##
# If there is any argument, parse the input.
# NOTE this will parse with 'getopt', some machine does not support.
if [ $# -ne 0 ]; then
    ## CLI Input Parser ##
    # This section is modified base on: 
    # https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
    # Comment marked with * was created by the original author and Nickel have no clue what he/she is talking

    # * saner programming env: these switches turn some bugs into errors
    set -o errexit -o pipefail -o noclobber -o nounset

    # Notice in some bash shell getopt is not supported.
    # For example, macOS does not come with gnu-getopt and you need to brew install it.
    # If getopt is not supported on the machine, user always have option to use the
    # interactive mode below.
    # * allow a command to fail with !’s side effect on errexit
    # * use return value from ${PIPESTATUS[0]}, because ! hosed $?
    ! getopt --test > /dev/null 
    if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
        echo "$0: 'getopt --test' failed. Please try this script"
        echo "with no arguments to enter interactive mode."
        exit 1
    fi

    # Project options:
    # Vivado only       vivado      v
    # Vitis             vitis       t
    # Software          software    s
    # Gitignore         git         g
    # All               all         a

    # Also Specify:
    # path to project   path:       p:
    # project name      name:       n:
    # help              help        h

    OPTIONS=vtsgap:n:h
    LONGOPTS=vivado,vitis,software,git,all,path:,name:,help,noreadme

    # * regarding ! and PIPESTATUS see above
    # * temporarily store output to be able to check for errors
    # * activate quoting/enhanced mode (e.g. by writing out “--options”)
    # * pass arguments only via   -- "$@"   to separate them correctly
    ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # * e.g. return value is 1
        # *  then getopt has complained about wrong arguments to stdout
        echo "$0: use '-h' or '--help' to see helper for this script."
        exit 2
    fi
    # * read getopt’s output this way to handle the quoting right:
    eval set -- "$PARSED"

    # * now enjoy the options in order and nicely split until we see --
    while true; do
        case "$1" in
            -a|--all)
                VIVADO=y
                VITIS=y
                SOFTWARE=y
                GIT=y
                shift
                ;;
            -g|--git)
                GIT=y
                shift
                ;;
            -h|--help)
                helper
                exit 0
                ;;
            -n|--name)
                PRJ_NAME="$2"
                shift 2
                ;;
            --noreadme)
                NO_README=y
                shift
                ;;
            -p|--path)
                PRJ_PATH="$2"
                shift 2
                ;;
            -s|--software)
                SOFTWARE=y
                shift
                ;;
            -t|--vitis)
                VITIS=y
                shift
                ;;
            -v|--vivado)
                VIVADO=y
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "$0: invalid input."
                echo "$0: use '-h' or '--help' to see helper for this script."
                exit 2
                ;;
        esac
    done
    ## End of CLI Input Parser ##
else
    ## Interactive Input Mode ##
    echo -e "No input arguments, enter interactive mode.\n"

    echo "If you do not want to use interactive mode, you can pass arguments to the script."
    echo -e "To see helper, run 'bash $0 --help'\n"
    
    if ask "Create Vivado project?" Y; then
        VIVADO=y
    fi
    echo ""

    if ask "Create Vitis project?" N; then
        VITIS=y
    fi
    echo ""

    if ask "Create Software folder?" N; then
        SOFTWARE=y
    fi
    echo ""

    echo "Default .gitignore file will ensure only source code and scripts will be pushed."
    if ask "Create .gitignore file in project directory?" Y; then
        GIT=y
    fi
    echo ""

    # If something to do, ask for project name and location.
    if [ "$VIVADO" = "y" ] || [ "$VITIS" = "y" ] || [ "$SOFTWARE" = "y" ] || [ "$GIT" = "y" ]; then
        # Read me file as place holder?
        echo "By default a README.md file will be generated in each directory to make sure all"
        echo "directories will be uploaded to git."
        if ! ask "Create README.md?" Y; then
            NO_README=y
        fi
        echo ""

        # Ask for project name
        echo -e "Default project name is: ${C_GREEN}$PRJ_NAME${C_NC}"
        echo -n "Project name? [ENTER for default] "
        read input
        if [ ! -z "$input" ]; then
            PRJ_NAME=$input
        fi 
        echo ""
        
        # Ask for where to create project
        echo -e "Default project location is: ${C_GREEN}$PRJ_PATH${C_NC}"
        echo -n "Where to create project? [ENTER for default] "
        read input
        # If input is not ENTER, update project path.
        if [ ! -z "$input" ]; then
            PRJ_PATH=$input
        fi 
        echo ""
    fi
    ## End of Interactive Input Mode ##
fi

# Check if any option is y, if all no, quit.
if [ "$VIVADO" = "n" ] && [ "$VITIS" = "n" ] && [ "$SOFTWARE" = "n" ] && [ "$GIT" = "n" ]; then
    echo "$0: nothing to do, exit."
    echo "$0: use '-h' or '--help' to see helper for this script."
    exit 0
fi

# Display vitis warning message
if [ "$VIVADO" = "n" ] && [ "$VITIS" = "y" ]; then
    echo "Note Vitis project script assume you have 'vivado' folder that contain XSA file."
    echo -e "You may need to modify Vitis project generation script.\n"
fi

# Display git warining message
if [ "$GIT" = "n" ]; then
    echo "Use default .gitignore file is highly recommended."
    echo -e "Please reference from the default .gitignore if you are using git.\n"
fi

# Check if directory path already exist.
if [ -d "$PRJ_PATH" ] && [ ! $PRJ_PATH = "." ]; then
    echo -e "${C_YELLOW}Warning${C_NC}: Directory $PRJ_PATH already exist.\n"
fi
## End of Argument Parser ##

## DEBUG ##
# echo "VIVADO:   $VIVADO"
# echo "VITIS:    $VITIS"
# echo "SW:       $SOFTWARE"
# echo "GIT:      $GIT"
# echo "PATH:     $PRJ_PATH"
# echo "NAME:     $PRJ_NAME"
# echo "NOREADME: $NO_README"
# echo ""
## DEBUG ##

create() {
    # source folder
    if [ "$VIVADO" = "y" ] || [ "$VITIS" = "y" ] || [ "$SOFTWARE" = "y" ]; then
        check_path "$PRJ_PATH/source/" ${1:-}
        if [ "$VIVADO" = "y" ]; then
            check_path "$PRJ_PATH/source/hdl/" ${1:-}
            check_path "$PRJ_PATH/source/hdl/block_designs/" ${1:-}
            check_path "$PRJ_PATH/source/hdl/xilinx_ips/" ${1:-}
            check_path "$PRJ_PATH/source/hvl/" ${1:-}
            check_path "$PRJ_PATH/source/xdc/" ${1:-}
        fi
        if [ "$VITIS" = "y" ]; then
            check_path "$PRJ_PATH/source/fw/" ${1:-}
        fi
        if [ "$SOFTWARE" = "y" ]; then
            check_path "$PRJ_PATH/source/sw/" ${1:-}
        fi
    fi

    # vivado folder
    if [ "$VIVADO" = "y" ]; then
        check_path "$PRJ_PATH/vivado/" ${1:-}

        if [ "${1:-}" = "real" ]; then
            create_vivado_sh "$PRJ_PATH/vivado/$PRJ_NAME.sh"
        else
            check_file "$PRJ_PATH/vivado/$PRJ_NAME.sh"
        fi

        if [ "${1:-}" = "real" ]; then
            create_vivado_tcl "$PRJ_PATH/vivado/$PRJ_NAME.tcl"
        else
            check_file "$PRJ_PATH/vivado/$PRJ_NAME.tcl"
        fi
        # Will copy any script contain 'vivado' in their name
        VIVADO_FILES=$(find . -name "*vivado*")
        for f in $VIVADO_FILES; do
            if [ "${1:-}" = "real" ]; then
                cp $f $PRJ_PATH/vivado/${f##*/}
            else
                check_file "$PRJ_PATH/vivado/${f##*/}"
            fi
        done
    fi

    # vitis folder
    if [ "$VITIS" = "y" ]; then
        check_path "$PRJ_PATH/vitis/" ${1:-}
        # Will copy any script contain 'vitis' in their name
        VITIS_FILES=$(find . -name "*vitis*")
        for f in $VITIS_FILES; do
            if [ "${1:-}" = "real" ]; then
                cp $f $PRJ_PATH/vitis/${f##*/}
            else
                check_file "$PRJ_PATH/vitis/${f##*/}"
            fi
        done
    fi

    # software folder
    if [ "$SOFTWARE" = "y" ]; then
        check_path "$PRJ_PATH/software/" ${1:-}
    fi

    # gitignore
    if [ "$GIT" = "y" ]; then
        if [ "${1:-}" = "real" ]; then
            cp ./.gitignore $PRJ_PATH/.gitignore
        else
            check_file "$PRJ_PATH/.gitignore"
        fi
    fi
}

## Ask for Directory and File Creation ##
echo "The following directories and files will be created:"
create 
# [[ "$NO_README" = "n" ]] && echo "README.md will also be created in each directory."
echo ""

if ! ask "Continue?" Y; then
    echo "$0: no file or directory created."
    exit 0
fi

## Create Directories and Files ##
create "real"
echo "Directories and Files has been created."

## Create Vivado Project ##


## Launch Vivado ##