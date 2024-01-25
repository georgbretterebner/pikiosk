#!/bin/bash

uid=$(id -u)
export XDG_RUNTIME_DIR=/run/user/$uid

# /usr/bin/cage -- /home/kiosk/cef/cefsimple --url="$url"
weston