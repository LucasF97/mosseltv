#!/bin/bash
sleep 5 # wacht even tot netwerk is opgestart

source /home/lucas/mosseltv/venv/bin/activate
export DISPLAY=:0
python3 /home/lucas/mosseltv/app.py
