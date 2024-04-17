#!/usr/bin/env bash

CUR_STATE=$(gsettings get org.gnome.desktop.peripherals.touchpad send-events)
NEW_STATE=$([ "${CUR_STATE}" = "'enabled'" ] && echo "'disabled'" || echo "'enabled'")

gsettings set org.gnome.desktop.peripherals.touchpad send-events "${NEW_STATE}"
