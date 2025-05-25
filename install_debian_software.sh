#!/bin/bash

# for nodejs/opencommit
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# apt packages
sudo apt update
sudo apt install -y \
mpv                            `# for video playing` \
sxiv                           `# for pictures` \
strace                         `# for tracing` \
docker.io                      `# containers` \
docker-compose                 `# containers` \
ffmpeg          	       `# for video` \
v4l2loopback-dkms	       `# for obs-studio` \
obs-studio          	       `# for screen recording` \
peek            	       `# for screen recording` \
nodejs                         `# for opencommit` \
python3-pip          	       `# pip` \
bat \
locales \
scrot                          `# screenshots` 


sudo docker swarm init
sudo docker stack deploy -c ollama-stack.yaml ollama

# this is needed for pavucontrol/docker working not under sudo only
for group in audio pulse-access pulse docker
do	
  sudo usermod -a -G $group $USER
done


# background removal for obs-studio
if [ ! -d /usr/share/obs/obs-plugins/obs-backgroundremoval ]
then	
  wget https://github.com/occ-ai/obs-backgroundremoval/releases/download/1.1.10/obs-backgroundremoval-1.1.10-x86_64-linux-gnu.deb
  sudo apt install -y ./obs-backgroundremoval-1.1.10-x86_64-linux-gnu.deb
  rm -f obs-backgroundremoval-1.1.10-x86_64-linux-gnu.deb
fi


# install opencommit
if ! command -v opencommit &> /dev/null
then
  sudo npm install -g opencommit	
  oco config set OCO_AI_PROVIDER=ollama
fi	

# install pet
if ! command -v pet &> /dev/null
then	
  wget https://github.com/knqyf263/pet/releases/download/v0.3.6/pet_0.3.6_linux_amd64.deb
  sudo apt install -y ./pet_0.3.6_linux_amd64.deb
  rm -f pet_0.3.6_linux_amd64.deb
fi  

# install tui scripts
if ! command -v a &> /dev/null
then	
  curl -O "https://git.digitalstudium.com/digitalstudium/tui-scripts/releases/download/latest/tui-scripts_$(curl -s https://git.digitalstudium.com/digitalstudium/tui-scripts/raw/branch/main/VERSION)-1.deb"
  sudo apt install -y ./tui-scripts_*.deb
  rm -f tui-scripts*
fi  

# install sshtui
if ! command -v sshtui &> /dev/null
then
  curl -O "https://git.digitalstudium.com/digitalstudium/sshtui/raw/branch/main/sshtui"
  sudo install ./sshtui /usr/local/bin/
  rm -f ./sshtui
fi

