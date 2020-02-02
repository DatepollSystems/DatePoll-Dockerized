read -p "Are you sure you want to install / reinstall DatePoll-Frontend? [y/N] " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

echo "> Removing old installed version..."
rm -rf ./code/frontend/
echo "> Done"

echo "> Fetching DatePoll-Frontend zip"
cd ./code/
wget https://share.dafnik.me/DatePoll-Frontend-Releases/DatePoll-Frontend-latest.zip
echo "> Done"

echo "> Unzipping..."
unzip DatePoll-Frontend-latest.zip
echo "> Done"

echo "> Creating frontend folder..."
mkdir frontend
echo "> Done"

echo "> Moving files into position..."
mv DatePoll-Frontend/* frontend/
echo "> Done"

echo "> Cleaning up..."
rm -rf DatePoll-Frontend/
rm DatePoll-Frontend-latest.zip
echo "> Done"

else
  exit 0
fi
