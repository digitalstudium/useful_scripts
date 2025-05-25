#!/bin/bash
# for nvidia-container-toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# for nodejs/opencommit
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# obs-studio repo
sudo add-apt-repository ppa:obsproject/obs-studio -y
# for tensorrt (remove backgrount in obs)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
rm -f cuda-keyring_1.1-1_all.deb

# apt packages
sudo nala update
sudo nala install -y \
mpv                            `# for video playing` \
sxiv                           `# for pictures` \
strace                         `# for tracing` \
docker.io                      `# containers` \
docker-compose                 `# containers` \
nvidia-container-toolkit       `# containers` \
nodejs          	       `# for opencommit` \
ffmpeg          	       `# for video` \
v4l2loopback-dkms	       `# for obs-studio` \
obs-studio          	       `# for screen recording` \
python3-pip          	       `# pip` \
tensorrt-libs \
bat \
locales \
fzf \
scrot                          `# screenshots` \
libreadline-dev                `# for nnn` \
nnn                	       `# nnn is file manager` \
pandoc                	       `# pandoc onvers markdown to html` \
cutycapt                       `# for converting html to image` \
vifm                	       `# vifm is file manager` \
farbfeld               	       `# for sent`

sudo locale-gen ru_RU
sudo locale-gen ru_RU.UTF-8
sudo update-locale

# lf settings
sudo cp lf_preview.sh /usr/local/bin
cat << 'EOF' > lfrc
set sixel true
set previewer lf_preview.sh
cmd trash %set -f; mv $fx ~/.trash
map <delete> trash
map i $batcat --force-colorization $f
map x $$f
map o $mimeopen --ask $f
EOF

sudo mkdir /etc/lf
sudo cp lfrc /etc/lf
rm -f lfrc

if [ ! -f /etc/docker/daemon.json ]
then	
  sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
  sudo service docker restart
fi

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

# install lf
if ! command -v lf &> /dev/null
then
  wget https://github.com/gokcehan/lf/releases/download/r31/lf-linux-amd64.tar.gz
  tar -xvzf lf-linux-amd64.tar.gz
  sudo mv ./lf /usr/local/bin/
  rm -f lf-linux-amd64.tar.gz
fi	

# install lazygit
if ! command -v lazygit &> /dev/null
then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin	
    rm -rf ./lazygit*
fi	

# install opencommit
if ! command -v opencommit &> /dev/null
then
  git clone --depth 1 https://git.digitalstudium.com/digitalstudium/opencommit.git
  cd opencommit
  npm run build
  npm pack
  sudo npm install -g opencommit-3.0.11.tgz
  cd -
  rm -rf opencommit
  oco config set OCO_AI_PROVIDER=ollama
fi	

# install pet
if ! command -v pet &> /dev/null
then	
  wget https://github.com/knqyf263/pet/releases/download/v0.3.6/pet_0.3.6_linux_amd64.deb
  sudo apt install -y ./pet_0.3.6_linux_amd64.deb
  rm -f pet_0.3.6_linux_amd64.deb
fi  

# install kubectl
if ! command -v kubectl &> /dev/null
then	
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"	
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi  

