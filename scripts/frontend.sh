#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Formatting escape codes.
RED='\033[0;31m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Print an error message and exit the program.
errorAndExit() {
  printf "\n${RED}ERROR:${NC} %s\n" "$1"
  exit 1;
}

# Set up an exit handler so we can print a help message on failures.
_success=false
shutdown () {
  if [ $_success = false ]; then
    printf "\nYour DatePoll frontend installation did not complete successfully.\n"
    printf "Please report your issue at https://github.com/DatePoll/DatePoll/DatePoll-Frontend/issues\n\n"
  fi
  rm -rf "$INSTALL_TEMP_DIRECTORY"
}
trap shutdown INT TERM ABRT EXIT

# Define install and tmp folder
if ! [ "${FRONTEND_INSTALL_DIRECTORY:-}" ]; then
  FRONTEND_INSTALL_DIRECTORY="$(pwd)/code/frontend"
fi
INSTALL_TEMP_DIRECTORY="$(pwd)/code/tmp/"

# Define version and check args for it
VERSION=latest
FORCE=false

while getopts "v:fh" opt; do        
    case "${opt}" in
        h)
            printf "${BOLD}DatePoll-Frontend install help${NC}:\n"
            printf "Usage: ./code/frontend.sh -v [version] -f\n"
            printf "    -v ['dev', 'rc']    (optional) selects a specific version to install\n"
            printf "    -f                  (optional) force install DatePoll-Frontend without asking for confirmation\n"
            _success=true
            exit 1;
        ;;
        f)
            echo "-f was triggered, force install..."
            FORCE=true
        ;;
        v)
            echo "-v was triggered, Parameter: $OPTARG" >&2
            if [ "$OPTARG" == "rc" ]
            then
                VERSION=rc
            elif [ "$OPTARG" == "dev" ]
            then
                VERSION=dev
            else
                errorAndExit "Option -v $OPTARG argument incorrect. Please use: rc - Release candidate or dev - development version" 
            fi
        ;;
        \?)
            errorAndExit "Option -v $OPTARG argument incorrect. Please use: rc - Release candidate or dev - development version" 
        ;;
        :)
            errorAndExit "Option -v $OPTARG requires an argument. Examples: rc - Release candidate, dev - development version" 
        ;;
    esac
done

# Activity spinner for background processes.
spinner() {
  local -r delay='0.3'
  local spinstr='\|/-'
  local temp
  while ps -p "$1" >> /dev/null; do
    temp="${spinstr#?}"
    printf " [${BLUE}%c${NC}]  " "${spinstr}"
    spinstr=${temp}${spinstr%"${temp}"}
    sleep "${delay}"
    printf "\b\b\b\b\b\b"
  done
  printf "\r"
}

# Check for a required tool, or exituccess
requireTool() {
  which "$1" >> /dev/null && EC=$? || EC=$?
  if [ $EC != 0 ]; then
    errorAndExit "Could not locate \"$1\", which is required for installation."
  fi
}

# Check sudo permissions
checkPermissions() {
    echo -en "Checking for sufficient permissions... "
    if [ "$(id -u)" -ne "0" ]; then
    echo -e "\e[31mfailed\e[0m"
    errorAndExit "Unsufficient permissions. Sudo required!"
    fi
    echo -e "\e[32mOK\e[0m"
}

main () {
    # Confirm install with user input
    if [ $FORCE == false ]; then
        read -p "Are you sure you want to install / update DatePoll-Frontend? [y/N] " prompt
        if [[ $prompt != "y" && $prompt != "Y" && $prompt != "yes" && $prompt != "Yes" ]]
        then
            _success=true
            errorAndExit "User aborted. Next time press ['y', 'Y', 'yes', 'Yes'] to continue"
        fi
    fi
    
    # Check for sufficient permissions
    checkPermissions
    
    # Check if required tools are installed
    requireTool "curl"
    requireTool "mv"
    requireTool "rm"
    requireTool "unzip"
    requireTool "docker-compose"
    requireTool "docker"
    requireTool "git"
    
     # Determine operating system & architecture (and exit if not supported)
    case $(uname -s) in
        "Linux")
        case "$(uname -m)" in
        "x86_64")
            ;;
        *)
            errorAndExit "Unsupported CPU architecture $(uname -m)"
            ;;
        esac
        ;;
        *)
        errorAndExit "Unsupported operating system $(uname -s)"
        ;;
    esac
    
    printf "Using version: ${BOLD}${VERSION}${NC}\n"
    
    FRONTEND_DOWNLOAD_URL="https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-${VERSION}.zip"
    
    printf "${BLUE}Clearing${NC} tmp folder"
    (rm -rf "${INSTALL_TEMP_DIRECTORY}" && mkdir "${INSTALL_TEMP_DIRECTORY}") & spinner $!
    printf "${GREEN}Successfully${NC} cleared tmp folder [${GREEN}✓${NC}]\n"
    
    # Download release
    printf "${BLUE}Downloading${NC} DatePoll-Frontend-${VERSION}.zip"
    curl -s -L ${FRONTEND_DOWNLOAD_URL} --output "${INSTALL_TEMP_DIRECTORY}/DatePoll-Frontend-${VERSION}.zip" & spinner $!
    printf "${GREEN}Successfully${NC} downloaded DatePoll-Frontend-${VERSION} [${GREEN}✓${NC}]\n"
    
    # Unzip downloaded release
    printf "${BLUE}Unzipping${NC} DatePoll-Frontend-${VERSION}.zip... "
    unzip -qq "${INSTALL_TEMP_DIRECTORY}DatePoll-Frontend-${VERSION}.zip" -d "${INSTALL_TEMP_DIRECTORY}" & spinner $!
    printf "${GREEN}Successfully${NC} unzipped DatePoll-Frontend-${VERSION}.zip [${GREEN}✓${NC}]\n"
    
    # Recreate frontend install folder
    printf "${BLUE}Clearing${NC} frontend install folder... "
    (rm -rf "$FRONTEND_INSTALL_DIRECTORY" 2>/dev/null && mkdir "$FRONTEND_INSTALL_DIRECTORY" 2>/dev/null) & spinner $!
    printf "${GREEN}Successfully${NC} cleared frontend install folder [${GREEN}✓${NC}]\n"
    
    # Move files into place
    printf "${BLUE}Moving${NC} files into place... "
    mv "${INSTALL_TEMP_DIRECTORY}/DatePoll-Frontend/" "${FRONTEND_INSTALL_DIRECTORY}/*" 2>/dev/null & spinner $!
    printf "${GREEN}Successfully${NC} moved files into place [${GREEN}✓${NC}]\n"
    
    # Set 777 permissions
    printf "${BLUE}Applying${NC} permissions... "
    chmod -R 777 "$FRONTEND_INSTALL_DIRECTORY" 2>/dev/null & spinner $!
    printf "${GREEN}Successfully${NC} applied permissions [${GREEN}✓${NC}]\n"
    
    # Restart docker container network
    printf "${BLUE}Restarting${NC} docker containers..."
    (docker-compose down 2>/dev/null && docker-compose up -d 2>/dev/null) & spinner $!
    printf "${GREEN}Successfully${NC} restarted docker container [${GREEN}✓${NC}]\n"
    
    _success=true

    printf "${GREEN}Finished${NC} the frontend update ${BOLD}flawlessly${NC}.\n"
    printf "Visit ${UNDERLINE}https://gitlab.com/DatePoll/DatePoll/datepoll-frontend/-/releases${NC} to learn more about the latest updates."
    printf "\n\n"
}

main
