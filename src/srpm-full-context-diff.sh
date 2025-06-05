#!/bin/bash

# @brief This is tool for simple and fast comparing 2 RPMS in meld tool.
#        Main purpose is to be able review changes made by patches in full context
#        of understanding where and what changed in files.
# @encoding utf-8$
# @author Jakub Haruda

set -eo pipefail

declare -ri _EC_SCRIPT_IS_SOURCED=1
declare -ri _EC_CANNOT_LOAD_LIBRARY=2

is_this_script_sourced() {
    # @return 0 if it is sourced, otherwise 1
    [[ "$0" != "${BASH_SOURCE[0]}" ]]
}

if is_this_script_sourced; then
    echo "ERROR: This script can't be sourced"
    return "$_EC_SCRIPT_IS_SOURCED"
fi

this_script_path="$( realpath "$0" )"
this_script_dir="$( dirname $this_script_path )"
this_script_filename="$( basename $this_script_path )"


# enironment variables definition
[ -n "$BHF_DEBUG" ] && set -x
source "${this_script_dir}/../config/bhf_lib_env.sh"
COMPARE_TOOL="${COMPARE_TOOL:-meld}"
set +x
export BHF_FULL_DIR_PATH="$( dirname "$BHF_FULL_PATH" )"

source "$BHF_FULL_PATH" || exit "$_EC_CANNOT_LOAD_LIBRARY"
bhf_print_debug "${this_script_filename}: the library 'BASH Helper Functions' - BHF succesfuly sourced"


declare -r PACKAGE_DATA_OLD="data_old"
declare -r PACKAGE_DATA_NEW="data_new"
SRPM_FILENAME_OLD="old.src.rpm"
SRPM_FILENAME_NEW="new.src.rpm"

#Currently only supported, but you can change it for example to `git diff`

# Types of SRPM
declare -r SRPM_TYPE_OLD="old"
declare -r SRPM_TYPE_NEW="new"


func_called_info() {
    [ -z "$1" ] && bhf_error_exit "'func_called_info' called without function parameter"
    bhf_function_called_info "$1" "$this_script_filename"
}


extract_srpm_to_folder() {
    func_called_info "$FUNCNAME"
    local output_path="$1"
    local srpm_file="$2"
    local srpm_type="$3"
    mkdir "$output_path"
    bhf_print_debug "Extracting ${srpm_type} Source RPM."

    rpm --define "_topdir ${output_path}" -i ${srpm_file} 2>/dev/null || {
        bhf_error_exit "Problems extracting files from SRPM"
    }
    bhf_print_success "SRPM ${srpm_type} is extracted."
}


apply_patches() {
    func_called_info "$FUNCNAME"
    local output_path="$1"
    local srpm_type="$2"
    bhf_print_info "Applying patches for ${srpm_type} SRPM."
    local specpath=${output_path}/SPECS/*spec
    cp $specpath "tmp.spec"
    # %patchN is not supported format, so we are converting it to %patch N format
    sed -i "s/^%patch\([0-9]\)/%patch \1/g" $specpath
    rpmbuild --nodeps --define "_topdir ${output_path}" \
               -bp $specpath
    mv "tmp.spec" $specpath
    bhf_print_info "SRPM patches for version '${srpm_type}' applied."
}


download_srpm() {
    func_called_info "$FUNCNAME"
    declare -r url="$1"
    declare -r srpm_type="$2"

    bhf_print_info "Downloading ${srpm_type} SRPM from WEB ${url}"
    if ! bhf_url_is_available "$url"; then
        # The file does not exist on web
        bhf_error_exit "URL ${srpm_type} SRPM does not exists"
    fi
    bhf_print_info "SRPM URL detected for --old package"
    local srpm_filename=$( basename "$url" )
    if [ -f "$srpm_filename" ]; then
        bhf_print_warning "There is already ${srpm_type} package SRPM in folder \`$srpm_filename\`"

        if bhf_dialog_yes "Are you sure you want to overwrite it with the new file from the web"; then
            rm -f $srpm_filename
            bhf_print_warning "SRPM will be overwriten - ${srpm_type}"
        else
            # Use of wget -nc will not have any effects
            bhf_print_info "Using existing ${srpm_type} SRPM version in this folder"
        fi
    fi
    wget -nc "$url" || {
        bhf_error_exit "Problem downloading new SPRM"
    }
    bhf_print_info "SRPM downloaded - ${srpm_type}"
}


compare_spec() {
    func_called_info "$FUNCNAME"
    specfile_old=$( find data_old/SPECS/ -name "*.spec" )
    specfile_new=$( find data_new/SPECS/ -name "*.spec" )
    bhf_print_info "Comparing old SPEC file and new SPEC file"
    bhf_print_info "Old SPEC file path: $specfile_old"
    bhf_print_info "New SPEC file path: $specfile_new"
    $COMPARE_TOOL "$specfile_old" "$specfile_new"
}


compare_data() {
    func_called_info "$FUNCNAME"
    bhf_print_info "Getting paths with source codes."
    patched_folder_old=$( ls -d data_old/BUILD/* | head -n 1 )
    patched_folder_new=$( ls -d data_new/BUILD/* | head -n 1 )

    bhf_print_info "In old SRPM There are $( ls data_old/SOURCES/*.patch | wc -l ) patches"
    ls data_old/SOURCES/*.patch || true
    bhf_print_info "In new SRPM There are $( ls data_new/SOURCES/*.patch | wc -l ) patches"
    ls data_new/SOURCES/*.patch || true

    bhf_print_success "We have paths (old ${patched_folder_old}) (new ${patched_folder_new})"
    bhf_print_info "Starting comparing 2 SRPMS packages using \`$COMPARE_TOOL\`"
    $COMPARE_TOOL "$patched_folder_old" "$patched_folder_new"
}


check_compare_tool() {
    func_called_info "$FUNCNAME"

    bhf_command_exists "$COMPARE_TOOL" || {
        bhf_error_exit "The program '$COMPARE_TOOL' is not installed."
    }
    bhf_print_info "The tool/workflow '$COMPARE_TOOL' is available"
}


srpm_extract() {
    # Check if folder with data already exists.
    # If not (normal case), then create them and extract srpm inside them.
    # If they already exists, then use that data for comparasion.
    local srpm_file="$1"
    local srpm_type="$2"
    declare -r output_path="$(pwd)/data_${srpm_type}"

    if [ -d "$output_path" ]; then
        bhf_print_warning "There is already old folder \`$output_path\`"
        if bhf_dialog_yes "'${srpm_type}' - folder for extracting SRPM data already exists."`
                          `"Are you sure you want to overwrite"; then
            bhf_print_warning "Removing old folder \`$output_path\`"
            rm -r "$output_path"

            extract_srpm_to_folder "$output_path" "$srpm_file" "$srpm_type"
            apply_patches "$output_path" "$srpm_type"
        else
            bhf_print_warning "Using existing extracted SRPM data 'old' folder"
        fi
    else
        extract_srpm_to_folder "$output_path" "$srpm_file" "$srpm_type"
        apply_patches "$output_path" "$srpm_type"
    fi
}


print_help() {
    echo "The script is for comparing 2 Source RPM (SRPM) packages."
    echo "" 
    echo "This is tool for simple and fast comparing 2 source RPMS in the 'meld' (https://meldmerge.org) tool."
    echo "Main purpose is to be able review changes made by patches in full context"
    echo "of understanding where and what changed in files. Current version only support appling all patches"
    echo "stored in SRPM without oprion to disable few patches."
    echo ""
    echo "  Supported usage:"
    echo ""
    echo "   1) You can compare 2 RPMS files stored on WEB. It  will be downloaded to your local system:"
    echo "     $ rsr-sfcd --old https://fedora.com/srpms/my_older_package.src.rpm \\"
    echo "                  --new https://fedora.com/srpms/my_newer_package.src.rpm"
    echo ""
    echo "   2) You can compare 2 RPMS files stored in your system:"
    echo "     $ rsr-sfcd --old my_older_package.src.rpm --new my_newer_package.src.rpm"
    echo ""
    echo ""
    echo ""
    echo "     $ rsr-sfcd [--new <uri|nvr>] [--old <uri|nvr>] [--help] [--verbose]"
    echo ""
    echo "  Options:"
    echo ""
    echo "     -n, --new <uri|nvr>           The new SRPM URI or build NVR"
    echo ""
    echo "     -o, --old <uri|nvr>           The old SRPM URI or build NVR"
    echo ""
    echo "     -h, --help                    Print this help"
    echo ""
    echo "     -v, --verbose                 Print more output from this program. It is eqvivalent of setting BHF_DEBUG=1"
    echo -e "\n\n\n\n"
    bhf_help_print_bhf_info
}


params_parser() {
    func_called_info "$FUNCNAME"
    # Parsing command line arguments - skeleton
    while (( $# )); do
        case "$1" in
            --help|-h)
                 print_help
                 exit 0 ;;
            --new|-n)
                 [ -z "$2" ] && bhf_error_exit "Missing new SRPM on command line after the parameter '--new'"
                 param_new="$2"
                 shift ;;
            --old|-o)
                 [ -z "$2" ] && bhf_error_exit "Missing old SRPM on command line after the parameter '--old'"
                 param_old="$2"
                 shift ;;
            --verbose|-v)
                 BHF_DEBUG=1 ;;
            *)
                 bhf_error_exit "Invalid parameter on command line" ;;
        esac
        shift
    done
}


params_print() {
    func_called_info "$FUNCNAME"
    if [ -n "$BHF_DEBUG" ]; then
        bhf_print_debug "-------------------------------------------------------"
        bhf_print_debug "PARAM 'param_new'=${param_new}"
        bhf_print_debug "PARAM 'param_old'=${param_old}"
        bhf_print_debug "GLOBAL 'BHF_DEBUG'=${BHF_DEBUG}"
        bhf_print_debug "GLOBAL 'BHF_SILENCE_FUNC_CALL'=${BHF_SILENCE_FUNC_CALL}"
        bhf_print_debug "-------------------------------------------------------"
    fi
}


params_check() {
    func_called_info "$FUNCNAME"
    [ -z "$param_old" ] && bhf_error_exit "The '--old' param not set"
    [ -z "$param_new" ] && bhf_error_exit "The '--new' param not set"
    return 0
}


fetch_srpm() {
    func_called_info "$FUNCNAME"
    local -r uri_nvr="$1"
    local -r srpm_type="$2"
    [ ! -f "$uri_nvr" ] && bhf_error_exit "${srpm_type} -  SRPM \`${uri_nvr}\` not found"
    return 0
}


main() {
    func_called_info "$FUNCNAME"
    local param_old param_new
    params_parser "$@"
    params_print
    params_check
    #echo "$( bhf_uri_protocol_type "$param_uri" "$PWD" )"
    #echo "$( bhf_filename_id_type "$param_uri" )"

    check_compare_tool

    bhf_print_info "Check if SRPM files exists"

#    old_protocol="$( bhf_uri_protocol_type "$param_old" )"
#    bhf_print_debug "'old' type - $old_protocol"
#    if [[ "$old_protocol" == "${BHF_URI_PROTOCOL_TYPE['HTTPS']}" ]] || \
#        [[ "$old_protocol" == "${BHF_URI_PROTOCOL_TYPE['HTTP']}" ]]; then
#        download_srpm "$param_old"
#        filename_old="$( basename "${param_old}" )"
#    elif [[ "$old_protocol" == "${BHF_URI_PROTOCOL_TYPE['PATH_RELATIVE_FILE']}" ]]; then
#        filename_old="$param_old"
#    fi
#
#    new_protocol="$( bhf_uri_protocol_type "$param_new" )"
#    bhf_print_debug "'new' type - $new_protocol"
#    if [[ "$new_protocol" == "${BHF_URI_PROTOCOL_TYPE['HTTPS']}" ]] || \
#        [[ "$new_protocol" == "${BHF_URI_PROTOCOL_TYPE['HTTP']}" ]]; then
#        download_srpm "$param_new"
#        filename_new="$( basename "${param_new}" )"
#    elif [[ "$new_protocol" == "${BHF_URI_PROTOCOL_TYPE['PATH_RELATIVE_FILE']}" ]]; then
#        filename_new="$param_new"
#    fi
    filename_old="$param_old"
    filename_new="$param_new"

    bhf_print_info "Using the 'old' package: $filename_old"
    bhf_print_info "Using the 'new' package: $filename_new"

    srpm_extract "$filename_old" "$SRPM_TYPE_OLD"
    srpm_extract "$filename_new" "$SRPM_TYPE_NEW"

    compare_data
    compare_spec
    bhf_print_success "Finished. :) See you later."
}


main "$@"


