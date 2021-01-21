#!/usr/bin/env bash

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

read -p "Are you sure you want to install / reinstall DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

	echo "> Removing old installed version..."
	rm -rf ./code/backend/
	echo "> Done"

	echo "> Fetching DatePoll-Backend"
	git clone https://gitlab.com/DatePoll/datepoll-backend-php.git ./code/backend/
	echo "> Done"

	echo "> Restarting docker container"
	docker-compose down
	docker-compose up -d
	echo "> Done"

	echo "> Installing composer libraries..."
	docker-compose exec datepoll-php php /usr/local/bin/composer install --ignore-platform-reqs
	echo "> Done"

	echo "> Copying .env file..."
	cd ./code/backend/
	cp .env.dockerized .env
	echo "> Done"

	echo "> Setting up .env file..."
	cd ../../
	docker-compose exec datepoll-php php artisan setup-datepoll
	echo "> Done"

	echo "> Migrating database..."
	docker-compose exec datepoll-php php artisan migrate --force
	## Execute update datepoll db command to set the current application db version into the database
	docker-compose exec datepoll-php php artisan update-datepoll-db
	echo "> Done"

	read -p "Do you want to add an default admin user? [y/N] " prompt
	if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
	then
		docker-compose exec datepoll-php php artisan add-admin-user
	else
	  	exit 0
	fi

	echo "> Restarting docker container"
	docker-compose down
	docker-compose up -d --remove-orphans
	echo "> Finished"

else
  echo "bye!"
  exit 0
fi
