read -p "Are you sure you want to upgrade DatePoll-Backend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    cd ./code/backend/

    echo "> Fetching new version"

    while getopts ":v:" opt; do
	  case $opt in
	    v)
	      echo "-v was triggered, Parameter: $OPTARG" >&2
	      if [ "$OPTARG" == "rl" ]
	      then
	        echo "> Fetching rl version..."
	        git fetch origin
			git reset --hard origin/master
	      else
	        echo "> Fetching dev version..."
	        git fetch origin
			git reset --hard origin/development
	      fi
	      ;;
	    \?)
	      echo "Invalid option: -$OPTARG" >&2
	      exit 1
	      ;;
	    :)
	      echo "Option -$OPTARG requires an argument. Example: dev - dev, dev..." >&2
	      exit 1
	      ;;
	  esac
	done
	
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
