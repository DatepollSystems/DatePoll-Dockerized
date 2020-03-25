read -p "Are you sure you want to upgrade DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    cd ./code/backend/

    echo "> Checking if update is available..."
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
        echo "> Nothing to do... Bye!"
        exit 0
    elif [ $LOCAL = $BASE ]; then
        echo "> Fetching new DatePoll-Backend"
        git pull
    else
        echo "> Can not continue! Git repository is out of sync!"
        exit 0;
    fi
    echo "> Done"

    echo "> Setting permissions..."
    chmod -R 777 ./*
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
