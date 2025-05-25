#!/usr/bin/env python3
import sys, os, subprocess

help_text = f"""
Usage: {os.path.basename(__file__)} $1 $2

required:
  $1 - name of service
  $2 - calendar ()
"""

number_of_required_arguments = 2
number_of_optional_arguments = 0

if len(sys.argv) == 1:
    print(help_text)
    sys.exit() 
elif sys.argv[1] in ["help", "-h"]:
    print(help_text)
elif len(sys.argv) - 1 < number_of_required_arguments:
    print(f"You provided not enough arguments")
    print(help_text)
    sys.exit(1)
elif len(sys.argv) > number_of_required_arguments + number_of_optional_arguments + 1:
    print(f"You provided extra arguments")
    print(help_text)
    sys.exit(1)
    
name_of_service = sys.argv[1]
calendar = sys.argv[2]

timer_file = f"""
[Unit]
Description={name_of_service} timer

[Timer]
Unit={name_of_service}.service
OnCalendar={calendar}

[Install]
WantedBy=timers.target
"""

try:
  with open(f"/lib/systemd/system/{name_of_service}.timer", "w") as f:
    f.write(timer_file)
  os.system(f"systemctl enable --now {name_of_service}.timer && echo Success!!!")
except:
    print("Something went wrong...")
    sys.exit(1)

