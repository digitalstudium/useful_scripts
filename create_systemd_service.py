#!/usr/bin/env python3
import sys, os, subprocess

help_text = f"""
Usage: {os.path.basename(__file__)} $1 $2 $3

required:
  $1 - name of service
  $2 - absolute path to script

optional:
  $3 - description of service
"""
number_of_required_arguments = 2
number_of_optional_arguments = 1

if len(sys.argv) == 1:
    print(help_text)
    sys.exit() 
elif sys.argv[1] in ["help", "-h"]:
    print(help_text)
    sys.exit()
elif len(sys.argv) - 1 < number_of_required_arguments:
    print(f"You provided not enough arguments")
    print(help_text)
    sys.exit(1)
elif len(sys.argv) > number_of_required_arguments + number_of_optional_arguments + 1:
    print(f"You provided extra arguments")
    print(help_text)
    sys.exit(1)
    
name_of_service = sys.argv[1]
path_to_script = sys.argv[2]
description = sys.argv[3] if sys.argv[3:4] else ""  # empty if no description

if not os.path.isabs(path_to_script):
    print("Path to script should be absolute!")
    print(help_text)
    sys.exit(1)
elif not os.path.isfile(path_to_script):
    print("Path to script should exist and must be file!")
    print(help_text)
    sys.exit(1)
    

service_file = f"""
[Unit]
Description={description}
After=network-online.target

[Service]
Type=oneshot
ExecStart={path_to_script}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""

try:
  with open(f"/lib/systemd/system/{name_of_service}.service", "w") as f:
    f.write(service_file)
  subprocess.run(f"chmod +x {path_to_script}", shell=True, check=True)
  os.system(f"systemctl enable --now {name_of_service} && echo Success!!!")
except:
    print("Something went wrong...")
    sys.exit(1)

