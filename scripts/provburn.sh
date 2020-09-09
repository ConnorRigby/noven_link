#!/usr/bin/env bash
export NERVES_HUB_KEY=`cat nerves-hub/NRPI300000001-key.pem` 
export NERVES_HUB_CERT=`cat nerves-hub/NRPI300000001-cert.pem` 
export NERVES_SERIAL_NUMBER="NRPI300000001" 
# export NOVEN_URL="ws://192.168.1.122:4000/device_socket/websocket?token=a88gdF7lsFlCA4D2fxf5q3HgPNWaeaEXc2TwmOkZiFA"
export NOVEN_URL="https://noven.app/device_socket/websocket?token=Hf87lVgf_NDC0iCrtsC0-acLhFYMLvMeqY6cOMPYLWI"
export NERVES_PROVISIONING=provisioning.conf
sudo -E fwup -i /home/connor/workspace/noven/noven_link/_build/rpi3_dev/nerves/images/noven_link.fw -a -t upgrade