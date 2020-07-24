#!/usr/bin/env bash

version=master

# Check permissions
echo -en "Checking for sufficient permissions... "
if [ "$(id -u)" -ne "0" ]; then
  echo -e "\e[31mfailed\e[0m"
  exit 1
fi
echo -e "\e[32mOK\e[0m"

for bin in docker-compose docker git; do
  if [[ -z $(which ${bin}) ]]; then echo "Cannot find ${bin}, exiting..."; exit 1; fi
done

while getopts ":v:" opt; do
  case $opt in
    v)
      echo "-v was triggered, Parameter: $OPTARG" >&2
      if [ "$OPTARG" == "dev" ]
      then
        echo "> Using dev version..."
        version=dev
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Example: dev - dev version" >&2
      exit 1
      ;;
  esac
done

read -p "Are you sure you want to update DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    
  cd ./code/backend/

	if [ "$version" == "master" ]
  then
		echo "> Fetching master branch..."
	  git fetch origin
		git reset --hard origin/master
	else
    echo "> Fetching development version..."
	  git fetch origin
		git reset --hard origin/development
	fi
	
  echo "> Done"

  echo "> Setting permissions..."
  chmod -R 777 ./*
  echo "> Done"

  echo "> Installing composer libraries..."
  docker-compose exec datepoll-php php /usr/local/bin/composer install
  echo "> Done"

  echo "> Migrating database..."
  cd ../../
  docker-compose exec datepoll-php php artisan migrate --force
  docker-compose exec datepoll-php php artisan update-datepoll-db
  echo "> Done"

  echo "> Restarting docker container"
  docker-compose down
  docker-compose up -d
  echo "> Finished!"

else
  echo "bye!"
  exit 0
fi
