read -p "Are you sure you want to upgrade DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

echo "> Fetching new DatePoll-Backend"
cd ./code/backend/
git pull
echo "> Done"

echo "> Installing composer libraries..."
composer install
echo "> Done"

echo "> Migrating database..."
cd ../../
docker-compose exec php php /backend/artisan migrate
docker-compose exec php php /backend/artisan update-datepoll-db
echo "> Done"

echo "> Restarting docker container"
docker-compose down
docker-compose up -d
echo "> Done"

else
  exit 0
fi
