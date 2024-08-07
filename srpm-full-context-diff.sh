#!/bin/bash


# @brief This is tool for simple and fast comparing 2 RPMS in meld tool. 
#        Main purpose is to be able review changes made by patches in full context 
#        of understanding where and what changed in files.
# @encoding utf-8
# @author Jakub 'Harry' Haruda


PACKAGE_DATA_FOLDER=data_

PACKAGE_DATA_OLD=data_old
PACKAGE_DATA_NEW=data_new

SRPM_FILENAME_OLD="old.src.rpm"
SRPM_FILENAME_NEW="new.src.rpm"

COMPARE_TOOL_BINARY="meld" #Currently only supported, but you can change it for example to `git diff`



readonly EXIT_INVALID_URL=1
readonly EXIT_INVALID_ARGV=2
readonly EXIT_SRPM_FILE_NOT_EXISTS=3
readonly EXIT_INVALID_ARGV_MODE=4
readonly EXIT_MISSING_BINARY=5
readonly EXIT_UNEXPECTED_STATE_OF_USER_SYSTEM=6
readonly EXIT_INVALID_LOGGER_TYPE=20


# COMPARE OLD AND NEW SRPM PATCHES


# Text logger types
readonly LOG_STAUS_ERROR="ERROR"
readonly LOG_STAUS_DEBUG="DEBUG"
readonly LOG_STAUS_WARNING="WARNING"
readonly LOG_STAUS_INFO="INFO"
readonly LOG_STAUS_SUCCESS="SUCCESS"
readonly LOG_STAUS_NORMAL="NORMAL"

# Coloring printed text 
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_ORANGE='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_WHITE='\033[0;37m'

# Types of SRPM
readonly SRPM_TYPE_OLD="old"
readonly SRPM_TYPE_NEW="new"

# brief Print message on stdout colored by state
# param $1 is status as text (see constants: LOG_STAUS_*)
# param $2 is text to print
function logger() {
    if [ $1 == $LOG_STAUS_ERROR ]; then
        printf "${COLOR_RED}[$1]: $2\033[0m\n"
    elif [ $1 == $LOG_STAUS_DEBUG ]; then
        printf "${COLOR_PURPLE}[$1]: $2\033[0m\n"
    elif [ $1 == $LOG_STAUS_WARNING ]; then
        printf "${COLOR_ORANGE}[$1]: $2\033[0m\n"
    elif [ $1 == $LOG_STAUS_INFO ]; then
        printf "${COLOR_BLUE}[$1]: $2\033[0m\n"
    elif [ $1 == $LOG_STAUS_SUCCESS ]; then
        printf "${COLOR_GREEN}[$1]: $2\033[0m\n"
    elif [ $1 == $LOG_STAUS_NORMAL ]; then
        echo $2 #Just print the message without formating
    else
        printf "${COLOR_RED}[ERROR]: Invalid logger type when calling this logger function\033[0m\n"
        exit $EXIT_INVALID_LOGGER_TYPE
    fi
}

# param $1 type of srpm (old or new)
function extract_srpm_to_folder() {
    mkdir ${PACKAGE_DATA_FOLDER}$1
    logger $LOG_STAUS_DEBUG "Extracting $1 source rpm."

    if [ $1 == $SRPM_TYPE_OLD ]; then
        rpm --define "_topdir $(pwd)/${PACKAGE_DATA_FOLDER}old" -i $SRPM_FILENAME_OLD 2>/dev/null
    else
        rpm --define "_topdir $(pwd)/${PACKAGE_DATA_FOLDER}new" -i $SRPM_FILENAME_NEW 2>/dev/null
    fi

    logger $LOG_STAUS_DEBUG "SRPM $1 is extracted."

    logger $LOG_STAUS_DEBUG "Applying patches for $1 SRPM."
    rpmbuild --nodeps --define "_topdir $(pwd)/${PACKAGE_DATA_FOLDER}$1" -bp $(pwd)/${PACKAGE_DATA_FOLDER}$1/SPECS/*spec
    logger $LOG_STAUS_DEBUG "SRPM $1 patches applied." 
}


logger $LOG_STAUS_INFO "We need (graphical) meld tool for comparing." 
#In the future we maybe add also support for non-meld comaprision/git diff"
if [ ! command -v meld &> /dev/null ]; then
    logger $LOG_STAUS_ERROR "Meld program is not installed! (https://meldmerge.org/)"
    logger $LOG_STAUS_WARNING "First you need to install it! (sudo apt get install meld -y / sudo dnf install meld -y"
    exit $EXIT_MISSING_BINARY
fi
logger $LOG_STAUS_DEBUG "Meld is installed"



print_help() {
    echo \
"This is tool for simple and fast comparing 2 source RPMS in meld tool. 
Main purpose is to be able review changes made by patches in full context 
of understanding where and what changed in files. Current version only support appling all patches
stored in SRPM without oprion to disable few patches.

Supported ussage: You run program from terminal in current directory.
 1) You can compare 2 RPMS files stored on WEB. It  will be downloaded to your local system:
    $ sfcd https://fedora.com/srpms/my_older_package.src.rpm https://fedora.com/srpms/my_newer_package.src.rpm --wget

 2) You can compare 2 RPMS files stored in your system:
    $ sfcd my_older_package.src.rpm my_newer_package.src.rpm"
}

if [ $# -eq 0 ]; then
    logger $LOG_STAUS_WARNING "No arguments suppliend. Using default filenames of SRPMS."
elif [ $1 == 'help' ] || [ $1 == '--help' ] || [ $1 == '-h' ]; then
    print_help
    exit 0
else
    if [ $# -eq 2 ]; then
        #Using relative/absolute path form first and second command line argument
        SRPM_FILENAME_OLD=$1
        SRPM_FILENAME_NEW=$2
    elif [ $# -eq 3 ]; then
        if [ $3 == 'web' ] || \
           [ $3 == '--web' ] || \
           [ $3 == 'wget' ] || \
           [ $3 == 'url' ] || \
           [ $3 == '--wget' ] || \
           [ $3 == '--url' ]; then
            #Use URL fromfirst and second command line argument. In this case also third argument must be defined and specify WGET(URL) mode

            logger $LOG_STAUS_INFO "Using WEB downloading mode"
            logger $LOG_STAUS_INFO "Downloading old SRPM from WEB $1"
            if timeout 5 wget -q --method=HEAD $1; then #Check if exists on the web
                logger $LOG_STAUS_DEBUG "Old SRPM URL detected"
                SRPM_FILENAME_OLD=$(basename "$1")
                if [ -f $SRPM_FILENAME_OLD ]; then
                    logger $LOG_STAUS_WARNING "There is already old package SRPM in folder \`$SRPM_FILENAME_OLD\`"
                    read -p "Are you sure you want to overwrite it with the new file from the web (y/n)? " dialog_overwrite_old
                    if [[ $dialog_overwrite_old == [yY] ]]; then
                        rm -f $SRPM_FILENAME_OLD
                        logger $LOG_STAUS_INFO "Old SRPM will be overwriten"
                    else
                        # Use of wget -nc will not have any effects
                        logger $LOG_STAUS_WARNING "Using existing old SRPM version in this folder"
                    fi
                fi
                wget -nc $1
            else
                logger $LOG_STAUS_ERROR "URL old SRPM does not exists"
                exit $EXIT_INVALID_URL
            fi

            logger $LOG_STAUS_INFO "Downloading new SRPM from WEB $2"
            if timeout 5 wget -q --method=HEAD $2; then #Check if exists on the web
                logger $LOG_STAUS_DEBUG "New SRPM URL detected"
                SRPM_FILENAME_NEW=$(basename "$2")
                if [ -f $SRPM_FILENAME_NEW ]; then
                    logger $LOG_STAUS_WARNING "There is already new package SRPM file in folder \`$SRPM_FILENAME_NEW\`"
                    read -p "Are you sure you want to overwrite with the new file from the web (y/n)? " dialog_overwrite_new
                    if [[ $dialog_overwrite_new == [yY] ]]; then
                        rm -f $SRPM_FILENAME_NEW
                        logger $LOG_STAUS_INFO "New SRPM will be overwriten"
                    else
                        # Use of wget -nc will not have any effects
                        logger $LOG_STAUS_WARNING "Using existing new SRPM version in this folder"
                    fi
                fi
                wget -nc $2
            else
                logger $LOG_STAUS_ERROR "URL new SRPM does not exists"
                exit $EXIT_INVALID_URL
            fi
            logger $LOG_STAUS_SUCCESS "Old and new srpm downloaded"
        else
            logger $LOG_STAUS_ERROR "Invalid third argument. It must be something like URL/WGET to use URL mode"
            exit $EXIT_INVALID_ARGV_MODE
        fi
    else
        logger "$LOG_STAUS_ERROR" "Invalid count of command line arguments"
        exit $EXIT_INVALID_ARGV
    fi
fi

logger $LOG_STAUS_INFO "Check SRPM files exists"
if [ ! -f $SRPM_FILENAME_OLD ]; then
    logger $LOG_STAUS_ERROR "Old SRPM \`$SRPM_FILENAME_OLD\` not found"
    exit $EXIT_SRPM_FILE_NOT_EXISTS
fi

if [ ! -f $SRPM_FILENAME_NEW ]; then
    logger $LOG_STAUS_ERROR "NEW SRPM \`$SRPM_FILENAME_NEW\` not found"
    exit $EXIT_SRPM_FILE_NOT_EXISTS
fi


logger $LOG_STAUS_INFO "Using old package: $SRPM_FILENAME_OLD"
logger $LOG_STAUS_INFO "Using new package: $SRPM_FILENAME_NEW"


# Check if folder (data_old, data_new) already exists. If not (normal case) then create them and extract srpm inside them.
# If they already exists, then use they data for comparasion.
if [ -d "$PACKAGE_DATA_OLD" ]; then
    logger $LOG_STAUS_WARNING "There is already old folder \`$PACKAGE_DATA_OLD\`"
    read -p "Old folder for extracting SRPM data already exists. Are you sure you want to overwrite (y/n)? " dialog_overwrite_folder_old
    if [[ $dialog_overwrite_folder_old == [yY] ]]; then
        logger $LOG_STAUS_WARNING "Removing old folder \`$PACKAGE_DATA_OLD\`"
        rm -r "$PACKAGE_DATA_OLD"

        extract_srpm_to_folder $SRPM_TYPE_OLD
    else
        logger $LOG_STAUS_WARNING "Using existing extracted SRPM data old folder"
    fi
else
    extract_srpm_to_folder $SRPM_TYPE_OLD
fi



if [ -d "$PACKAGE_DATA_NEW" ]; then
    logger $LOG_STAUS_WARNING "There is already new folder \`$PACKAGE_DATA_NEW\`"
    read -p "New folder for extracting SRPM data already exists. Are you sure you want to overwrite (y/n)? " dialog_overwrite_folder_new
    if [[ $dialog_overwrite_folder_new == [yY] ]]; then
        logger $LOG_STAUS_WARNING "Removing new folder \`$PACKAGE_DATA_NEW\`"
        rm -r "$PACKAGE_DATA_NEW"

        extract_srpm_to_folder $SRPM_TYPE_NEW
    else
        logger $LOG_STAUS_WARNING "Using existing extracted SRPM data new folder"
    fi
else
    extract_srpm_to_folder $SRPM_TYPE_NEW
fi



logger $LOG_STAUS_INFO "Getting paths with source codes."
patched_folder_old=$(ls -d data_old/BUILD/* | head -n 1)
patched_folder_new=$(ls -d data_new/BUILD/* | head -n 1)

logger $LOG_STAUS_INFO "In old SRPM There are $(ls data_old/SOURCES/*.patch | wc -l) patches "
ls data_old/SOURCES/*.patch
logger $LOG_STAUS_INFO "In new SRPM There are $(ls data_new/SOURCES/*.patch | wc -l) patches "
ls data_new/SOURCES/*.patch

logger $LOG_STAUS_SUCCESS "We got paths (old $patched_folder_old) (new $patched_folder_new)"
logger $LOG_STAUS_INFO "Starting comparing 2 SRPMS packages use \`$COMPARE_TOOL_BINARY\`"
$COMPARE_TOOL_BINARY $patched_folder_old $patched_folder_new

specfile_old=$(find data_old/SPECS/ -name "*.spec")
specfile_new=$(find data_new/SPECS/ -name "*.spec")
logger $LOG_STAUS_INFO "Comparing old SPEC file and new SPEC file"
logger $LOG_STAUS_DEBUG "Old SPEC file path: $specfile_old"
logger $LOG_STAUS_DEBUG "New SPEC file path: $specfile_new"
$COMPARE_TOOL_BINARY $specfile_old $specfile_new


logger $LOG_STAUS_SUCCESS "Comparing finished. :o) See you later."
