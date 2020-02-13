read -p "Are you sure you want to upgrade DatePoll-Dockerized (sudo required)? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

	if [ ! -f ./scripts/dockerRound ]; then
    		echo "> Creating dockerRound file..."
		echo 0 > ./scripts/dockerRound
		echo "> Done..."
	fi

	file="./scripts/dockerRound"
	dockerRound=$(cat "$file")

	if [ $dockerRound == "0" ]
	then
		
		echo "> Checking if update is needed..."
		UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "$UPSTREAM")
        BASE=$(git merge-base @ "$UPSTREAM")

        if [ $LOCAL = $REMOTE ]; then
            echo "> Nothing to do... Bye!"
			exit 0
        elif [ $LOCAL = $BASE ]; then
            echo "> Fetching new DatePoll-Dockerized"
            git pull
        else
            echo "> Can not continue! Git repository is out of sync!"
            exit 0;
        fi
        echo "> Done"

		RED='\033[0;31m'
		NC='\033[0m' # No Color

		echo -e "${NC}> Done. ${RED}Please run this command again, just press Y in the next step! ${NC}"

		echo 1 > ./scripts/dockerRound

		./scripts/updateDatePollDocker.sh

	else
	  
		echo "> Shutting down docker container"
		docker-compose down
		echo "> Done"

		echo "> Rebuilding docker container"
		sudo docker-compose build
		echo "> Done"

		echo "> Starting docker container"
		docker-compose up -d
		echo "> Done. Everything is up to date!"

		echo 0 > ./scripts/dockerRound
	fi

else
  exit 0
fi
