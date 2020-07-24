#!/usr/bin/env bash

version=latest

# Check permissions
echo -en "Checking for sufficient permissions... "
if [ "$(id -u)" -ne "0" ]; then
  echo -e "\e[31mfailed\e[0m"
  exit 1
fi
echo -e "\e[32mOK\e[0m"

for bin in wget docker-compose docker git; do
  if [[ -z $(which ${bin}) ]]; then echo "Cannot find ${bin}, exiting..."; exit 1; fi
done

while getopts ":v:" opt; do
  case $opt in
    v)
      echo "-v was triggered, Parameter: $OPTARG" >&2
      if [ "$OPTARG" == "rc" ]
      then
        echo "> Using release candidate..."
        version=rc
      else
        echo "> Using dev version..."
        version=dev
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Example: rc - Release candidate, dev..." >&2
      exit 1
      ;;
  esac
done


read -p "Are you sure you want to install / update DatePoll-Frontend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    echo "> Fetching DatePoll-Frontend zip..."
    cd ./code/
    wget "https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-${version}.zip"
    echo "> Done"

    echo -en "> Unzipping... "
    unzip "DatePoll-Frontend-${version}.zip" >> /dev/null
    echo -e "\e[32mdone\e[0m"

    echo -en "> Removing old installed version... "
    rm -rf ./frontend/
    echo -e "\e[32mdone\e[0m"

    echo -en "> Creating frontend folder... "
    mkdir frontend
    echo -e "\e[32mdone\e[0m"

    echo -en "> Moving files into place... "
    mv DatePoll-Frontend/* frontend/
    echo -e "\e[32mdone\e[0m"
    
    echo -en "> Setting permissions... "
    chmod -R 777 ./frontend/
    echo -e "\e[32mdone\e[0m"

    echo -en "> Cleaning up... "
    rm -rf DatePoll-Frontend/
    rm "DatePoll-Frontend-${version}.zip"
    echo -e "\e[32mdone\e[0m"
    
    echo "> Restarting docker containers"
    cd ../
    docker-compose down
    docker-compose up -d
    echo "> Finished"

else
  echo "bye!"
  exit 0
fi

#!/bin/bash

version=$(git describe --tags $(git rev-list --tags --max-count=1))

echo "Project: DatePoll-Frontend"
echo "Type: Release"
echo "Version: $version"

rm -rf ./dist/*

echo "Building... "
ng build --prod
echo -e "\e[32mDone.\e[0m"


cd dist/

echo -en "Creating tar.xz... "
tar cfJ "DatePoll-Frontend-${version}.tar.xz" ./DatePoll-Frontend >> /dev/null
echo -e "\e[32mdone\e[0m"

echo -en "Creating zip... "
zip -r "DatePoll-Frontend-${version}.zip" ./DatePoll-Frontend >> /dev/null
echo -e "\e[32mdone\e[0m"

ls

echo "> Finished"
