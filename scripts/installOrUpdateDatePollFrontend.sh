version=latest

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

    echo "> Fetching DatePoll-Frontend zip"
    cd ./code/
    wget "https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-${version}.zip"
    echo "> Done"

    echo "> Unzipping..."
    unzip "DatePoll-Frontend-${version}.zip"
    echo "> Done"

    echo "> Removing old installed version..."
    rm -rf ./frontend/
    echo "> Done"

    echo "> Creating frontend folder..."
    mkdir frontend
    echo "> Done"

    echo "> Moving files into place..."
    mv DatePoll-Frontend/* frontend/
    echo "> Done"
    
    echo "> Setting permissions..."
    chmod -R 777 ./frontend/
    echo "> Done"

    echo "> Cleaning up..."
    rm -rf DatePoll-Frontend/
    rm "DatePoll-Frontend-${version}.zip"
    echo "> Done"
    
    echo "> Restarting docker containers"
    cd ../
    docker-compose down
    docker-compose up -d
    echo "> Done"

else
  exit 0
fi
