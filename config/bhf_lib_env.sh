declare -r BHF_SUBPATH="${BHF_SUBPATH:-bhf/src/bash_helper_functions_local.sh}"
declare -r BHF_RELATIVE_PATH="${BHF_RELATIVE_PATH:-/share}"
declare -r BHF_FULL_PATH="${BHF_FULL_PATH:-${this_script_dir}${BHF_RELATIVE_PATH}/${BHF_SUBPATH}}"

export BHF_FULL_DIR_PATH="$( dirname "$BHF_FULL_DIR_PATH" )"
