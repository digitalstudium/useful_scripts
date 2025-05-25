#!/bin/bash
# ubuntu hangs if network interface is not optional
if ! sudo grep -r optional /etc/netplan
then	
  sudo sed -i '/dhcp4/a\      optional: yes' /etc/netplan/00-installer-config-wifi.yaml
  sudo sed -i '/dhcp4/a\      optional: yes' /etc/netplan/00-installer-config.yaml
fi  
#  Add firefox repo
sudo bash -c 'echo "deb [trusted=yes] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list'
# By default ubuntu installs firefox from snap, so I want to disable it
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
# install packages I need
sudo apt update
sudo apt install -y nala
sudo nala install -y \
xorg                         `# for graphics` \
make                         `# for compiling gui` \
gcc                          `# for compiling gui` \
libx11-dev                   `# for compiling dwm` \
libxft-dev                   `# for compiling dwm` \
libxinerama-dev              `# for compiling dwm` \
libharfbuzz-dev              `# for compiling st` \
suckless-tools               `# for dmenu` \
ncdu                         `# for disk usage analysys` \
brightnessctl                `# for keyboard backlight` \
xcompmgr                     `# for st opacity` \
xwallpaper                   `# for background` \
ubuntu-wallpapers-jammy      `# backgrounds` \
pulseaudio                   `# for sound` \
alsa-base                    `# for sound` \
pavucontrol                  `# for audio control` \
pasystray                    `# for audio control` \
iputils-ping                 `# ping etc.` \
xfe                          `# classic file manager` \
surf                         `# suckless lightweight browser` \
micro                        `# console editor` \
neovim                       `# console editor` \
psmisc                       `# pstree etc.` \
slack \
firefox \
python3 \
python3-venv \
libnvidia-compute-545        `# for mpv + nvidia` \
nvidia-driver-545            `# nvidia driver` \
nvidia-cuda-toolkit          `# cuda driver`

# install telegram
if [ ! -d /opt/Telegram ]
then	
  if [ ! -f telegram.tar.xz ]
  then
  	curl -L https://telegram.org/dl/desktop/linux -o telegram.tar.xz
  fi	
  tar -xf telegram.tar.xz
  rm -f telegram.tar.xz
  sudo mv Telegram /opt/
fi

# remove snap cause I hate it
sudo systemctl disable --now snapd
sudo apt purge snapd -y
# remove autoinstalled stterm
sudo apt remove stterm -y


if [ ! -d ~/gui ]
then
  git clone https://git.digitalstudium.com/digitalstudium/ubuntu-gui ~/gui
fi

for tool in dwm st sent
do    
  # compiling dwm
  if ! command -v $tool &> /dev/null
  then
    cd ~/gui/$tool
    sudo make install clean
    cd -
  fi  
done

echo dwm > ~/.xinitrc  # for starting dwm when startx

for tool in create_systemd_service.py create_systemd_timer.py set_brightness.sh update_gui.sh
do    
  if ! command -v $tool &> /dev/null
  then
    sudo cp $tool /usr/local/bin
  fi  
done

git config --global user.name "Digital Studium"
git config --global user.email "digitalstudium001@gmail.com"

sudo create_systemd_service.py gui-updater /usr/local/bin/update_gui.sh
sudo create_systemd_timer.py gui-updater '*-*-* *:*:*'

if [ ! -d ~/.dwm ]
then
  mkdir $HOME/.dwm
fi  
echo "xhost +local:" > $HOME/.dwm/autostart.sh # give permissions to display
echo "xcompmgr &" >> $HOME/.dwm/autostart.sh  # for st opacity
echo "xwallpaper --stretch /usr/share/backgrounds/Blue_flower_by_Elena_Stravoravdi.jpg" >> $HOME/.dwm/autostart.sh  # background
echo "firefox &" >> $HOME/.dwm/autostart.sh
echo "Telegram &" >> $HOME/.dwm/autostart.sh
echo "st &" >> $HOME/.dwm/autostart.sh
echo "pasystray &" >> $HOME/.dwm/autostart.sh
chmod +x $HOME/.dwm/autostart.sh

sudo timedatectl set-timezone Europe/Moscow

sudo bash -c "echo 'PATH=\$(find /opt/ -executable -type f | grep -v \.so | xargs dirname | uniq | paste -s -d : | xargs -I _ echo \$PATH:_)' > /etc/profile.d/opt.sh"

