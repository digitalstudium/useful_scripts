#!/bin/bash
# install packages I need
sudo apt update
sudo apt install -y \
xserver-xorg                 `# for graphics` \
xinit                        `# for graphics` \
i3                           `# for graphics` \
x11-xserver-utils            `# for graphics` \
linux-headers-amd64	     `# needed for nvidia-driver installation` \
brightnessctl                `# for keyboard backlight` \
xcompmgr                     `# for st opacity` \
x11-apps                     `# for st opacity` \
stterm                       `# st` \
mate-backgrounds             `# for background` \
xwallpaper                   `# for background` \
pulseaudio                   `# for sound` \
pavucontrol                  `# for audio control` \
pasystray                    `# for audio control` \
iputils-ping                 `# ping etc.` \
neovim                       `# console editor` \
psmisc                       `# pstree etc.` \
software-properties-common   `# manage repos (needed for nvidia-driver installation)` \
chromium \
conky \
telegram-desktop \
python3 \
python3-venv \
network-manager \
network-manager-gnome \
curl

sudo update-alternatives --set x-terminal-emulator /usr/bin/st

# start window manager
cat > ~/.xinitrc << EOL
dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY & # because of slow Telegram start
xcompmgr -cC & # for st opacity
image=\$(find /usr/share/backgrounds/mate/nature/ -type f | sort --random-sort | head -1)
xwallpaper --stretch \$image
conky &
i3
EOL

# st opacity
if ! grep transset ~/.bashrc &> /dev/null; then
cat >> ~/.bashrc << EOL
term=\$(cat /proc/\$PPID/comm)
if [[ \$term == "x-terminal-emul" || \$term == "st" ]]; then
    transset 0.6 --id \$WINDOWID > /dev/null
fi
EOL
fi    

sudo add-apt-repository contrib non-free-firmware non-free -y
sudo apt update
sudo apt install nvidia-driver linux-image-amd64 -y


for tool in create_systemd_service.py create_systemd_timer.py set_brightness.sh
do    
  if ! command -v $tool &> /dev/null
  then
    sudo cp $tool /usr/local/bin
  fi  
done

git config --global user.name "Digital Studium"
git config --global user.email "digitalstudium001@gmail.com"

sudo timedatectl set-timezone Europe/Moscow

sudo sed -i s/desktop/override/g /etc/conky/conky.conf
sudo sed -i s/top_left/top_right/g /etc/conky/conky.conf
sudo bash -c "echo 'PATH=\$PATH:\$(find /opt/ -executable -type f | grep -v \.so | xargs dirname | uniq | paste -s -d : | xargs -I _ echo _)' > /etc/profile.d/opt.sh"

mkdir ~/.config/autostart
dex -c /usr/bin/chromium -t ~/.config/autostart
dex -c /usr/bin/telegram-desktop -t ~/.config/autostart
dex -c /usr/bin/st -t ~/.config/autostart

if ! grep TelegramDesktop ~/.config/i3/config &> /dev/null; then
cat >> ~/.config/i3/config << EOL
assign [class="Chromium"] 1
assign [class="TelegramDesktop"] 2
assign [class="st-256color"] 3
EOL
fi
