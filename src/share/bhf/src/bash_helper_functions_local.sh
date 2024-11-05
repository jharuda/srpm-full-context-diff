## BHF - The Bash Helper Functions Framework
#
# This file contains BASH functions for recuring BASH usecases like working with array, logging and all kinds
# of useful logic like simple dialog
#
# Minimal supported BASH version is 4.3
#
# This script must to be loaded directly using '.' or 'source' command.
#
#
# Template for your new script is placed in the 'bhf_template.sh' file. To generate a new script with use of this
# framework use command the 'bhf_init new_script_name' to create a new script with the BHF sceleton.
#
# The 'bhf_template.sh' is useful as a starting point for each script. It contains some definition that cant be
# placed directly to the 'BHF' library because this functionality is dependent on the caller context.
#
# There is a possibilty to use 'eval (source share/bhf/bash_helper_functions.sh)' and place more functionality
# to the 'BHF' but I want to avoid using the comman 'eval'
#
#
#
# Variables of this library you can use to change default behavior:
#          BHF_DEBUG=1                    - To print debug information - use this in the caller
#          BHF_NO_COLOR=1                 - To disable color - use this before calling your script
#          BHF_SILENCE_FUNC_CALL=1        - 'bhf_function_called_info' print debug info for each function call,
#                                            you can suppress this behavior to not be overhelmed with debug info.
#                                            This only make sense to use when you also set 'BHF_DEBUG=1'
#
#
# Please do not hesitate to add your name to the list of authors once you did some chnages in this framework
#
# @author Jakub Haruda <jharuda@redhat.com>

declare -r BHF_COLOR_RED='\033[0;31m'
declare -r BHF_COLOR_BLUE='\033[0;34m'
declare -r BHF_COLOR_BLUE_LIGHT='\033[0;36m'
declare -r BHF_COLOR_GREEN='\033[0;32m'
declare -r BHF_COLOR_YELLOW='\033[0;33m'
declare -r BHF_COLOR_DEFAULT='\033[0m'

# Constant defintion of exit codes for this library
declare -ri BHF_EC_LIB_BASE=130
declare -ri BHF_EC_BASE=150
declare -ri _BHF_EC_INCLUDE=$(( _BHF_EC_BASE + 1 ))
declare -ri _BHF_EC_EMPTY_VALUE_PARAM=$(( _BHF_EC_BASE + 2 ))
declare -ri _BHF_EC_VALUE_OUT_OF_RANGE=$(( _BHF_EC_BASE + 3 ))
declare -ri _BHF_EC_NOT_A_NUMBER=$(( _BHF_EC_BASE + 4 ))
declare -ri _BHF_EC_NOT_A_GIT_PATH=$(( _BHF_EC_BASE + 5 ))

# To print debug information use this in the caller script:
# HBF_DEBUG=1
BHF_DEBUG="${BHF_DEBUG:-""}"

# To disable color use this before calling your script:
# HBF_NO_COLOR=1
BHF_NO_COLOR="${BHF_NO_COLOR:-""}"

# This only make sense to use when you also set 'BHF_DEBUG=1'
BHF_SILENCE_FUNC_CALL="${BHF_SILENCE_FUNC_CALL:-""}"


# This sets number of spaces and parameters in the beggining of the line before description 
BHF_HELP_PARAM_DESC_COLUMN="${BHF_HELP_PARAM_DESC_COLUMN:-35}"
BHF_HELP_MAX_CHARS_PER_LINE="${BHF_HELP_PARAM_DESC_COLUMN:-120}"

bhf_print_error()
{
    if [ -n "$BHF_NO_COLOR" ]; then
        echo "ERROR:   ${1}"
    else
        echo -e "${BHF_COLOR_RED}ERROR:${BHF_COLOR_DEFAULT}   ${1}"
    fi
} >&2


bhf_print_info()
{
    if [ -n "$BHF_NO_COLOR" ]; then
        echo "INFO:    ${1}"
    else
        echo -e "${BHF_COLOR_BLUE_LIGHT}INFO:${BHF_COLOR_DEFAULT}    ${1}"
    fi
} >&2


bhf_print_debug()
{
    [ -z "$BHF_DEBUG" ] && return

    if [ -n "$BHF_NO_COLOR" ]; then
        echo "DEBUG:   ${1}"
    else
        echo -e "${BHF_COLOR_BLUE}DEBUG:${BHF_COLOR_DEFAULT}   ${1}"
    fi
} >&2


bhf_print_warning()
{
    if [ -n "$BHF_NO_COLOR" ]; then
        echo "WARNING: ${1}"
    else
        echo -e "${BHF_COLOR_YELLOW}WARNING:${BHF_COLOR_DEFAULT} ${1}"
    fi
} >&2


bhf_print_success()
{
    if [ -n "$BHF_NO_COLOR" ]; then
        echo "SUCCESS: ${1}"
    else
        echo -e "${BHF_COLOR_GREEN}SUCCESS:${BHF_COLOR_DEFAULT} ${1}"
    fi
} >&2



bhf_help_print_bhf_info()
{
    echo "  BHF framework:"
    echo "                 This sciprt uses \`BASH Helper Functions\` - BHF framework."
    echo "                 You can set the following variables before calling this program"
    echo 
    echo "     BHF_DEBUG=1                     To print all 'hbf' debug infromation. Eqvivalent of '-v|--verbose'"
    echo ""
    echo "     BHF_NO_COLOR=1                  To print all status information without color."
}


bhf_color_text()
{
    local -r color="$1"
    local -r text="$2"
    [ -z "$text" ] && bhf_error_exit "The first - 'text' parameter not set to the '${FUNCNAME}' function"
    [ -z "$color" ] && bhf_error_exit "The second - 'color' parameter not set to the '${FUNCNAME}' function"

    printf "${color}${text}${BHF_COLOR_DEFAULT}"
}


bhf_error_exit()
{
    # Optional 2nd parameter is a number for exit code in range 2-255
    # If the parameter is not supplied then 1 exit code is used by default
    bhf_print_error "$1"
    local -i exit_code="${2:-1}"
    bhf_print_info "Exiting"
    exit "$exit_code"
}


bhf_function_called_info()
{
    local -r func_name="$1"
    local -r script_name="${2:-BHF}"

    [ -n "$BHF_SILENCE_FUNC_CALL" ] && return 0
    [ -z "$func_name" ] && bhf_error_exit "You didn't pass the 'function name' 1st argument" "$_BHF_EC_EMPTY_VALUE_PARAM"

    bhf_print_debug "${script_name}: ${func_name}: Function called"
}


bhf_print_debug "BHF: BASH version is '$BASH_VERSION'"
BASH_VERSION_MAJOR="$(echo "$BASH_VERSION" | cut -d '.' -f1)"
BASH_VERSION_MINOR="$(echo "$BASH_VERSION" | cut -d '.' -f2)"
bhf_print_debug "BHF: Make sure we use BASH version 4.3 or newer"
if [ "$BASH_VERSION_MAJOR" -ge 5 ]; then
    bhf_print_debug "BHF: This BASH major version is supported"
elif [ "$BASH_VERSION_MAJOR" -eq 4 ] && [ "$BASH_VERSION_MINOR" -ge 3 ]; then
    bhf_print_debug "BHF: This BASH version is supported"
else
    bhf_error_exit "BHF: This BASH framework is not supported on your BASH version" "$_BHF_EC_INCLUDE"
fi


bhf_is_file_identical()
{
    bhf_function_called_info "$FUNCNAME"
    diff "$1" "$2" &>/dev/null
}


bhf_command_exists()
{

    bhf_function_called_info "$FUNCNAME"
    # Check if program specified in param $1 exists on this system
    # Optional parameter $2 - if set then print just debug info if the program is found
    local -r program="$1"
    local -r debug_only="${2:-}"

    if command -v "$program" &> /dev/null; then
        [ -n "$debug_only" ] && \
            bhf_print_debug "You have '${program}' command available on this system" || \
          bhf_print_info "You have '${program}' command available on this system"
        return 0
    else
        [ -n "$debug_only" ] && \
            bhf_print_debug "You do not have '${program}' command available" || \
          bhf_print_info "You do not have '${program}' command available"
        return 1
    fi
}


bhf_dialog_yes()
{
    bhf_function_called_info "$FUNCNAME"
    # param $1 is question to ask on input
    local answer
    read -p "${1}? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
        bhf_print_info "Continuing"
        return 0
    else
        bhf_print_info "Aborting"
        return 1
    fi
}


# Doesn't work for checking caller declare/local variables
# bhf_is_local_variable()
# {
#     local -n variable=$1
#     if ! local -p variable; then # || bhf_error_exit "The variable is not local"
#         bhf_error_exit "The variable is not local"
#     fi
# }


bhf_select_in_range()
{
    bhf_function_called_info "$FUNCNAME"
    # 'min' is bottom of the interval and 'max' is the highest possible number - the maximum value is included
    # min <= value <= max'
    local -ri min="$1"
    local -ri max="$2"
    local -i number
    declare -n options="$3"
    declare -n number_return="$4"

    [ -z "$options" ] && bhf_error_exit "BHF: bhf_select_in_range: 'option' variable doesn't have lines in the array" \
                                        "$_BHF_EC_EMPTY_VALUE_PARAM"
    [ -z "$min" ] && bhf_error_exit "BHF: bhf_select_in_range: 'min' variable not inicialized" \
                                    "$_BHF_EC_EMPTY_VALUE_PARAM"
    [ -z "$max" ] && bhf_error_exit "BHF: bhf_select_in_range: 'max' variable not inicialized" \
                                    "$_BHF_EC_EMPTY_VALUE_PARAM"

    echo "Select 'number' in interval: ${min} <= number <= ${max}"
    bhf_array_print options '<num>'
    # Selection dialog for more than one rule.
    while : ; do
        read -p "Select a rule between ${min} and ${max}: " number
        if [[ "$number" =~ ^[[:digit:]]+$ ]]; then
            if [ "$min" -le "$number" ] && [ "$number" -le "$max" ]; then
                bhf_print_debug "The number was accepted because it was in the expected range"
                break
            else
                bhf_print_warning "The number was not accepted because it was not in the expected range"
            fi
        else
             bhf_print_warning "You did not enter a number"
        fi
    done

    # Check are OK, so now we can return the value to caller
    number_return="$number"
}

bhf_find()
{
    # param $1 is path where to serach
    # param $2 is filename
    # Optional - 'type_of_content' param $3 to set type, otherwise the default is to filter by files
    # Optional - 'printf_format' param $4
    # Optional - 'case_insensitive' param $5 if set then use case-insensitive for finding files, otherwise the default
    #                               behaviour is case sensitive
    bhf_function_called_info "$FUNCNAME"
    local -r path="$1"
    local -r filename="$2"
    local -r type_of_content="${3:-f}"
    local -r printf_format="$4"
    local -r case_insensitive="$5"

#    [ -n "$3" ] && declare -n bhf_params_find_dict="$3"
    [ -z "$path" ] && bhf_error_exit "BHF: bhf_find_files: 'path' variable doesn't have assigned value" \
                                     "$_BHF_EC_EMPTY_VALUE_PARAM"
    [ -z "$filename" ] && bhf_error_exit "BHF: bhf_find_files: 'filename' variable doesn't have assigned value" \
                                         "$_BHF_EC_EMPTY_VALUE_PARAM"

    if [ -n "$case_insensitive" ]; then
        if [ -n "$printf_format" ]; then
            find "$path" -maxdepth 1 -iname "$filename" -type "$type_of_content" -printf "$printf_format"
        else
            find "$path" -maxdepth 1 -iname "$filename" -type "$type_of_content"
        fi
    else
        if [ -n "$printf_format" ]; then
            find "$path" -maxdepth 1 -name "$filename" -type "$type_of_content" -printf "$printf_format"
        else
            find "$path" -maxdepth 1 -name "$filename" -type "$type_of_content"
        fi
    fi
}


bhf_array_from_string()
{
    bhf_function_called_info "$FUNCNAME"
    declare -n arr_data="$1"
    local -r data="$2"

    [ -z "$data" ] && bhf_error_exit "BHF: bhf_array_from_string: The 'data' variable do not contain any data" \
                                     "$_BHF_EC_EMPTY_VALUE_PARAM"

    IFS=$'\n' readarray -t arr_data <<< "$data"
}


bhf_array_print()
{
    bhf_function_called_info "$FUNCNAME"
    # The first parameter is 'refname' to the array defined in caller we would like to print
    # The second parameter is optional. If it contains '<num>' text it will print number of item per line. If it
    #                      contains different text then the text will be placed in the beggining of each line
    # Note: Using -n to pass an array by reference - arr_data
    declare -n arr_data="$1"
    local prefix="$2"
    local index

    if ! [[ -v arr_data ]]; then
        bhf_print_warning "BHF: bhf_array_print: The array variable passed to this function by reference is not set"
        return "$_BHF_EC_EMPTY_VALUE_PARAM"
    fi
    bhf_print_debug "BHF: bhf_array_print: The array variable passed to this function by reference is set"

    # If the set array contains no records then we don't want to print just new line
    [ -z "$arr_data" ] && return
    bhf_print_debug "BHF: bhf_array_print: The array variable passed to this function by reference contains some data"

    for index in "${!arr_data[@]}"; do
        if [[ "$prefix" = '<num>' ]]; then
            echo "$((index+1)). ${arr_data[$index]}"
        elif [ -n "$prefix" ]; then
            echo "${prefix} ${arr_data[$index]}"
        else
            echo "${arr_data[$index]}"
        fi
    done
}


bhf_array_count()
{
    bhf_function_called_info "$FUNCNAME"
    # Note: Using -n to pass an array by reference - arr_data
    local -n arr_data="$1"

    ! [[ -v arr_data ]] && bhf_error_exit "The array variable passed to this function by reference is not set" \
                           "$_BHF_EC_EMPTY_VALUE_PARAM"

    echo ${#arr_data[@]}
}


bhf_string_remove_suffix()
{
    # It removes filename suffix and it returns filename without it
    echo "$1" | rev | cut -d'.' -f 2- | rev
}


bhf_string_at_end()
{
    bhf_function_called_info "$FUNCNAME"
    # Prints substring at the end of string the string in the parameter $1
    # optional param $2 is offset = how many symbols to return from end
    local -r string="$1"
    local -ri length=${#string}
    local -ri offset=${2:-1}

    echo "${string:${length}-${offset}:${offset}}"
}


bhf_git_branch_name()
{
    bhf_function_called_info "$FUNCNAME"
    local branch_canonical_name
    local -r repo_path="$1"
 
    [ -z "$repo_path" ] && \
            bhf_error_exit "You didn't pass a proper repository path argument" "$_BHF_EC_EMPTY_VALUE_PARAM"
 
    branch_canonical_name="$( git -C "$repo_path" symbolic-ref HEAD 2>/dev/null )" || \
                                    bhf_error_exit "You didn't pass proper repository path" "$_BHF_EC_NOT_A_GIT_PATH"

    echo "$branch_canonical_name" | rev | cut -d'/' -f 1 | rev
}


bhf_git_repository_name()
{
    bhf_function_called_info "$FUNCNAME"
    local -r repo_path="$1"
    local repo_fullpath

    [ -z "$repo_path" ] && bhf_error_exit "You didn't pass a repository path argument" "$_BHF_EC_EMPTY_VALUE_PARAM"

    repo_fullpath="$( git -C "$repo_path" rev-parse --show-toplevel 2>/dev/null )" || \
                              bhf_error_exit "You didn't pass proper repository path" "$_BHF_EC_NOT_A_GIT_PATH"
    basename "$repo_fullpath"
}


bhf_packages_install_list()
{
    bhf_function_called_info "$FUNCNAME"
    local -n packages_list="$1"
    local -r enable_repo="$2"
    local -r skip_broken="$3"

    local BHF_PACKAGE_MANAGER="${BHF_PACKAGE_MANAGER:-yum}"
    local pkg

    for pkg in "${packages_list[@]}"; do
        if [ -n "$skip_broken" ]; then
            $BHF_PACKAGE_MANAGER install -y "$pkg" --enablerepo="$enable_repo" --skip-broken
        else
            $BHF_PACKAGE_MANAGER install -y "$pkg" --enablerepo="$enable_repo"
        fi
    done
}


bhf_args_parser()
{
    # TODO
    bhf_function_called_info "$FUNCNAME"
    bhf_error_exit "'bhf_args_parser' not implemented"
}


declare -A BHF_URI_PROTOCOL_TYPE=(
    ['UNKNOWN']=0
    ['HTTPS']=1
    ['HTTP']=2
    ['SCP']=3
    ['PATH_ABSOLUTE_FILE']=4
    ['PATH_ABSOLUTE_DIR']=5
    ['PATH_ABSOLUTE_NON_EXISTING']=6
    ['PATH_RELATIVE_FILE']=7
    ['PATH_RELATIVE_DIR']=8
    ['PATH_RELATIVE_NON_EXISTING']=9
)


declare -A BHF_FILENAME_ID_TYPE=(
    ['UNKNOWN']=0
    ['PKG_FEDORA']=1
    ['PKG_EL']=2
    ['PKG_DEBIAN']=3
)


bhf_uri_protocol_type()
{
    bhf_function_called_info "$FUNCNAME"
    local -r uri="$1"
    local -r cwd="$2"
    [ -z "$uri" ] && bhf_error_exit "You didn't pass a URI argument" "$_BHF_EC_EMPTY_VALUE_PARAM"

    local protocol
    if [[ "$uri" =~ ^'https://' ]]; then
        protocol="${BHF_URI_PROTOCOL_TYPE['HTTPS']}"
    elif [[ "$uri" =~ ^'http://' ]]; then
        protocol="${BHF_URI_PROTOCOL_TYPE['HTTP']}"
    elif [[ "$uri" =~ ^'root@'*':'* ]]; then
        protocol="${BHF_URI_PROTOCOL_TYPE['SCP']}"
    elif [[ "$uri" =~ ^'/' ]]; then
        if [ -f "$uri" ]; then
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_ABSOLUTE_FILE']}"
        elif [ -d "$uri" ]; then
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_ABSOLUTE_DIR']}"
        else
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_ABSOLUTE_NON_EXISTING']}"
        fi
    else
        local path="${cwd}/${uri}"
        echo "$path" 1>&2
        if [ -f "$path" ]; then
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_RELATIVE_FILE']}"
        elif [ -d "$path" ]; then
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_RELATIVE_DIR']}"
        elif [[ "$uri" =~ '/' ]] || [[ "$uri" =~ '..' ]]; then
            protocol="${BHF_URI_PROTOCOL_TYPE['PATH_RELATIVE_NON_EXISTING']}"
        else
            protocol="${BHF_URI_PROTOCOL_TYPE['UNKNOWN']}"
        fi
    fi
    echo "$protocol"
}


bhf_filename_id_type()
{
    bhf_function_called_info "$FUNCNAME"
    local -r id_name="$1"
    [ -z "$id_name" ] && bhf_error_exit "You didn't pass a 'id_name'" "$_BHF_EC_EMPTY_VALUE_PARAM"
    local id_type

    if grep -q -E "^([[:alnum:]]|-)+([[:digit:]]|\.)+-([[:digit:]]|\.)+el[[:digit:]]{1,2}(_[[:digit:]])?$" <<< "$id_name"; then
        id_type="${BHF_FILENAME_ID_TYPE['PKG_EL']}"
    elif [[ "$id_name" =~ '.fc'[[:digit:]]+$ ]]; then
        id_type="${BHF_FILENAME_ID_TYPE['PKG_FEDORA']}"
    elif [[ "$id_name" =~ '.deb'$ ]]; then
        id_type="${BHF_FILENAME_ID_TYPE['PKG_DEBIAN']}"
    else
        id_type="${BHF_FILENAME_ID_TYPE['UNKNOWN']}"
    fi
    echo "$id_type"
}


bhf_url_is_available()
{
    bhf_function_called_info "$FUNCNAME"
    timeout 5 wget -q --method=HEAD $1
}
