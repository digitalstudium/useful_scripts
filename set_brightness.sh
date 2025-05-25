#!/bin/bash

H=$(date +%k)

if   (( $H >=  0 && $H <=  7 )); then
    /usr/bin/xrandr --output eDP --brightness .2
    sudo /usr/bin/brightnessctl --device='asus::kbd_backlight' set 1
elif (( $H >  7 && $H <= 10 )); then
    /usr/bin/xrandr --output eDP --brightness .5 
    sudo /usr/bin/brightnessctl --device='asus::kbd_backlight' set 1
elif (( $H > 10 && $H < 16 )); then
    /usr/bin/xrandr --output eDP --brightness .7 
    sudo /usr/bin/brightnessctl --device='asus::kbd_backlight' set 0
elif (( $H >= 16 && $H <= 19 )); then
    /usr/bin/xrandr --output eDP --brightness .4
    sudo /usr/bin/brightnessctl --device='asus::kbd_backlight' set 1
elif (( $H > 19 && $H <= 23 )); then
    /usr/bin/xrandr --output eDP --brightness .3
    sudo /usr/bin/brightnessctl --device='asus::kbd_backlight' set 1
else
    echo "Error"
fi

