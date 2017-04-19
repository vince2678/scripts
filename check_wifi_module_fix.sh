#!/bin/bash

function check_wifi_fix_enabled {
ARG="--wifi-fix"
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "$ARG" ]; then
		logb "\t\tWifi fix is enabled"
		WIFI_FIX=y
	fi
done
}

PRE_PATCH_FUNCTIONS=("${PRE_PATCH_FUNCTIONS[@]}" "check_wifi_fix_enabled")
