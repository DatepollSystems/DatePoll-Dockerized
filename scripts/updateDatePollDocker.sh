read -p "Are you sure you want to upgrade DatePoll-Dockerized (sudo required)? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
	echo "> Fetching new DatePoll-Dockerized"
	git pull
	echo "> Done"

	echo "> Shuting down docker container"
	docker-compose down
	echo "> Done"

	echo "> Rebuilding docker container"
	sudo docker-compose build
	echo "> Done"

	echo "> Starting docker container"
	docker-compose up -d
	echo "> Done! Please run this command two times!"
else
  exit 0
fi
