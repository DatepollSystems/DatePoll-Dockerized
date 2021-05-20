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
    printf "\nYour DatePoll backend update did not complete successfully.\n"
    printf "Please report your issue at https://gitlab.com/DatePoll/DatePoll/DatePoll-Dockerized/issues\n\n"
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

# Define version and check args for it
VERSION=latest
FORCE=false
SKIP_CONTAINER_RESTART=false

while getopts "v:fsh" opt; do        
    case "${opt}" in
        h)
            printf "${BOLD}DatePoll-Backend update help${NC}:\n"
            printf "Usage: ./code/backendUpdate.sh -v [version] -f\n"
            printf "    -v ['dev', 'rc']    (optional) selects a specific version to install\n"
            printf "    -f                  (optional) force updates DatePoll-Backend without asking for confirmation\n"
            printf "    -s                  (optional) skip container restart\n"
            _success=true
            exit 1;
        ;;
        f)
            echo "-f was triggered, force install..."
            FORCE=true
        ;;
        s)
            echo "-s was triggered, skip container restart..."
            SKIP_CONTAINER_RESTART=true
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

main () {
    # Confirm install with user input
    if [ $FORCE == false ]; then
        read -p "Are you sure you want to update DatePoll-Backend? [y/N] " prompt
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
    requireTool "chmod"
    
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
    
    cd ./code/backend/

    # Download release
    printf "${BLUE}Pulling${NC} DatePoll-Backend-${VERSION}\n"
    git fetch origin
    if [ "$VERSION" == "latest" ]
    then
      git reset --hard origin/master
    else
      git reset --hard origin/development
    fi    
    printf "\n${GREEN}Successfully${NC} pulled DatePoll-Backend-${VERSION} [${GREEN}✓${NC}]\n"
    
    # Set 777 permissions
    printf "${BLUE}Applying${NC} permissions... "
    chmod -R 777 ./* 2>/dev/null & spinner $!
    printf "${GREEN}Successfully${NC} applied permissions [${GREEN}✓${NC}]\n"

    # Updating composer libraries
    printf "${BLUE}Updating${NC} composer libraries \n"
    docker-compose exec datepoll-php php /usr/local/bin/composer install --ignore-platform-reqs
    printf "\n${GREEN}Successfully${NC} updated composer libraries [${GREEN}✓${NC}]\n"
    
    # Run database migrations
    printf "${BLUE}Migrating${NC} database... \n"
    (docker-compose exec datepoll-php php artisan migrate --force && docker-compose exec datepoll-php php artisan update-datepoll-db)
    printf "\n${GREEN}Successfully${NC} run database migrations [${GREEN}✓${NC}]\n"
       
    # Restart docker container network
    if [ $SKIP_CONTAINER_RESTART == false ]; then
      printf "${BLUE}Restarting${NC} docker containers..."
      (docker-compose down 2>/dev/null && docker-compose up -d 2>/dev/null) & spinner $!
      printf "${GREEN}Successfully${NC} restarted docker container [${GREEN}✓${NC}]\n"
    fi
    
    _success=true

    printf "${GREEN}Finished${NC} the backend update ${BOLD}flawlessly${NC}.\n"
    printf "Visit ${UNDERLINE}https://gitlab.com/DatePoll/DatePoll/datepoll-backend-php/-/releases${NC} or ${UNDERLINE}https://datepoll.org/docs/DatePoll/update${NC} to learn more about the latest updates.${NC}"
    printf "\n\n"
}

main
