useReleaseCanditate=false

while getopts ":v:" opt; do
  case $opt in
    v)
      echo "-v was triggered, Parameter: $OPTARG" >&2
      if [ "$OPTARG" == "rc" ]
      then
        echo "> Using release candidate..."
        useReleaseCanditate=true
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Example: rc - Release candidate" >&2
      exit 1
      ;;
  esac
done


read -p "Are you sure you want to install / update DatePoll-Frontend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

    echo "> Fetching DatePoll-Frontend zip"
    cd ./code/
    if [ "$useReleaseCanditate" = true ] ; then
        wget https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-rc.zip
    else
        wget https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-latest.zip
    fi
    echo "> Done"

    echo "> Unzipping..."
    if [ "$useReleaseCanditate" = true ] ; then
        unzip DatePoll-Frontend-rc.zip
    else
        unzip DatePoll-Frontend-latest.zip
    fi
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
    if [ "$useReleaseCanditate" = true ] ; then
        rm DatePoll-Frontend-rc.zip
    else
        rm DatePoll-Frontend-latest.zip
    fi
    echo "> Done"

else
  exit 0
fi
