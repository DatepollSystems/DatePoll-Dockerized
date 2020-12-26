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
    printf "\nYour DatePoll Dockerized update did not complete successfully.\n"
    printf "Please report your issue at https://github.com/DatePoll/DatePoll/DatePoll-Dockerized/issues\n\n"
  fi
}
trap shutdown INT TERM ABRT EXIT

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

FORCE=false

while getopts "v:fh" opt; do        
    case "${opt}" in
        h)
            printf "${BOLD}DatePoll-Dockerized update help${NC}:\n"
            printf "Usage: ./code/dockerUpdate.sh -f\n"
            printf "    -f                  (optional) force install DatePoll-Frontend without asking for confirmation\n"
            _success=true
            exit 1;
        ;;
        f)
            echo "-f was triggered, force install..."
            FORCE=true
        ;;
        \?)
            errorAndExit "Unknown option" 
        ;;
        :)
            errorAndExit "Unknown option" 
        ;;
    esac
done

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
    
    if [ ! -f ./scripts/dockerRound ]; then
        printf "${BLUE}Creating${NC} dockerRound file"
        echo 0 > ./scripts/dockerRound & spinner $!
        printf "${GREEN}Successfully${NC} created dockerRound file [${GREEN}✓${NC}]\n"
	fi
	
	file="./scripts/dockerRound"
	dockerRound=$(cat "$file")
	
    if [ $dockerRound == "0" ]
	then
        printf "${BLUE}Pulling${NC} latest release from master"
        (git fetch origin && git reset --hard origin/master) & spinner $!
        printf "${GREEN}Successfully${NC} pulled latest release from master [${GREEN}✓${NC}]\n"
        
        printf "${BLUE}Setting${NC} update scripts executable"
        chmod +x ./scripts/* & spinner $!
        printf "${GREEN}Successfully${NC} set update script executable [${GREEN}✓${NC}]\n"
        
        printf "${BLUE}Setting${NC} dockerRound file to 1"
        echo 1 > ./scripts/dockerRound & spinner $!
        printf "${GREEN}Successfully${NC} set update script executable to 1 [${GREEN}✓${NC}]\n"

		./scripts/dockerUpdate.sh -f
	else
	
        printf "${BLUE}Rebuilding${NC} docker container"
        (docker-compose down 2>/dev/null && sudo docker-compose build 2>/dev/null && docker-compose up -d 2>/dev/null) & spinner $!
        printf "${GREEN}Successfully${NC} rebuilded docker container [${GREEN}✓${NC}]\n"
        
        printf "${BLUE}Setting${NC} dockerRound file to 0"
        echo 0 > ./scripts/dockerRound & spinner $!
        printf "${GREEN}Successfully${NC} set update script executable to 0 [${GREEN}✓${NC}]\n"

        _success=true

        printf "\n"
        printf "${GREEN}Finished${NC} the docker installation update ${BOLD}flawlessly${NC}.\n"
        printf "\n\n"
	fi
}

main
