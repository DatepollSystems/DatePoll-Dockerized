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
		
		echo "> Pulling master"
		git fetch origin
		git reset --hard origin/master
        echo "> Done"

		RED='\033[0;31m'
		NC='\033[0m' # No Color

		echo "> Setting executable status on scripts..."
		chmod +x ./scripts/*
		echo "> Done"

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
