#!/bin/sh
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install libcurl4-openssl-dev libjansson-dev libomp-dev git screen nano jq wget
wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_arm64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_arm64.deb
rm libssl1.1_1.1.0g-2ubuntu4_arm64.deb
if [ ! -d ~/.ssh ]
then
  mkdir ~/.ssh
  chmod 0700 ~/.ssh
  cat << EOF > ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGru0cdToqirvhiaGERSFM38VXhsjJctA1e4DSttBQ+FGEEAXwppS5V04bpBvqXt9qTg8eW3U8B3qTvnMw0eYGTnQJ0MIFePe6DyytiiE9bXXCSJqu7HJ+6kAAPNjsJj6hA4aB3L3iYLM7i4duDytXu6T3WIZUc49E8dsoAafD5yiNycPEtAYsgGyOJVfeZ5g28swGgsUQjkJgpV9PJyFQtCWBXWIciIOUblVxPw6AFzAn4DkviM41bw9ipAzbwca9o0lndDDa7pRV1Gxc3dxOE8qrjPPLVB2lsYdBNbg3qXugKfOUODsRlBGNZchb2E9QV2w2CAvR4ysyL9qDaxpiS8Au5C14JNadIvqjdP03QYm9vFHVB7kWYXNhyBTkGeCIeTCiasVzhQ5hR7yB26/JU+I7kku/3dETqstrWxPXjPwUkt8LiR0ehH94U7fYIc35/ojPMMNtjR8kS+XUnMqa6nNr/5toy3FqHT9oAppf/rJRmVQF/5BiIhQVpbF8/OU= karls@DESKTOP-I7Q6I2S
EOF
  chmod 0600 ~/.ssh/authorized_keys
fi

if [ ! -d ~/ccminer ]
then
  mkdir ~/ccminer
fi
cd ~/ccminer

GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/CCminer-ARM-optimized/releases?per_page=1" | jq -c '[.[] | del (.body)]')
GITHUB_DOWNLOAD_URL=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets[0].browser_download_url")
GITHUB_DOWNLOAD_NAME=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets[0].name")

echo "Downloading latest release: $GITHUB_DOWNLOAD_NAME"

wget ${GITHUB_DOWNLOAD_URL} -P ~/ccminer

if [ -f ~/ccminer/config.json ]
then
  INPUT=
  while [ "$INPUT" != "y" ] && [ "$INPUT" != "n" ]
  do
    printf '"~/ccminer/config.json" already exists. Do you want to overwrite? (y/n) '
    read INPUT
    if [ "$INPUT" = "y" ]
    then
      echo "\noverwriting current \"~/ccminer/config.json\"\n"
      rm ~/ccminer/config.json
    elif [ "$INPUT" = "n" ]
    then
      echo "saving as \"~/ccminer/config.json.#\""
    else
      echo 'Invalid input. Please answer with "y" or "n".\n'
    fi
  done
fi
wget https://raw.githubusercontent.com/BakaKilluaTo/Android-Mining/main/config.json -P ~/ccminer

if [ -f ~/ccminer/ccminer ]
then
  mv ~/ccminer/ccminer ~/ccminer/ccminer_old
fi
mv ~/ccminer/${GITHUB_DOWNLOAD_NAME} ~/ccminer/ccminer
chmod +x ~/ccminer/ccminer

cat << EOF > ~/ccminer/start.sh
#!/bin/sh
#exit existing screens with the name CCminer
screen -S CCminer -X quit 1>/dev/null 2>&1
#wipe any existing (dead) screens)
screen -wipe 1>/dev/null 2>&1
#create new disconnected session CCminer
screen -dmS CCminer 1>/dev/null 2>&1
#run the miner
screen -S CCminer -X stuff "~/ccminer/ccminer -c ~/ccminer/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/.ccminer/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
EOF
chmod +x start.sh

echo "setup nearly complete."
echo "Edit the config with \"nano ~/ccminer/config.json\""

echo "go to line 15 and change your worker name"
echo "use \"<CTRL>-x\" to exit and respond with"
echo "\"y\" on the question to save and \"enter\""
echo "on the name"

echo "start the miner with \"cd ~/ccminer; ./start.sh\"."
