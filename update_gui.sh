#!/bin/bash
export DISPLAY=:0
set_brightness.sh  # set monitor brightness
battery_capacity=$(cat /sys/class/power_supply/BAT0/capacity)
MEM=$(free -h --kilo | awk '/^Mem:/ {print $3 "/" $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' )
DISK=$(df -Ph | grep "/dev/mapper/ubuntu--vg-ubuntu--lv" | awk {'print $5'})

/usr/bin/xsetroot -name "$battery_capacity% `date +"%a %d.%m %H:%M"`;MEM: $MEM CPU: $CPU% DISK: $DISK"  # set systray
