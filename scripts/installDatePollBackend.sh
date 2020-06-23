read -p "Are you sure you want to install / reinstall DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

	echo "> Removing old installed version..."
	rm -rf ./code/backend/
	echo "> Done"

	echo "> Fetching DatePoll-Backend"
	git clone https://gitlab.com/DatePoll/datepoll-backend-php.git ./code/backend/
	echo "> Done"

	echo "> Installing composer libraries..."
	cd ./code/backend/
	docker-compose exec datepoll-php php /usr/local/bin/composer install
	echo "> Done"

	echo "> Copying .env file..."
	cp .env.dockerized .env
	echo "> Done"

	echo "> Setting up .env file..."
	cd ../../
	docker-compose exec datepoll-php php artisan setup-datepoll
	echo "> Done"

	echo "> Migrating database..."
	docker-compose exec datepoll-php php artisan migrate
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
	docker-compose up -d
	echo "> Done"

else
  exit 0
fi
