#!/bin/sh

DEVICES_ID=$(xinput list | grep -iE "syn.*t|Elan TrackPoint" | awk '{print substr($6,4)}')

MATCHED_DEVICES=$(xinput list | grep -iE "syn.*t|Elan TrackPoint")
if [ -n "${MATCHED_DEVICES}" ]; then
  for DEVICE_LINE in ${MATCHED_DEVICES}; do
    DEVICES_ID=$(echo "${DEVICE_LINE}" | awk '{match($0,"id=([0-9]+)",m)}END{print m[1]}')
    if [ -n "${DEVICES_ID}" ]; then
      STATUS=-1
      for DEVICE_ID in ${DEVICES_ID}; do
        if [ ${STATUS} -eq -1 ]; then
          STATUS=$(xinput list-props ${DEVICES_ID} | grep "Device Enabled" | awk '{print $4}')
        fi

        if [ ${STATUS} -eq 0 ]; then
          xinput enable ${DEVICES_ID}
        elif [ ${STATUS} -eq 1 ]; then
          xinput disable ${DEVICES_ID}
        fi
      done
    fi
  done
fi
