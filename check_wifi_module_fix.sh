#!/bin/bash

function check_wifi_fix_enabled {
ARG="--wifi-fix"
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "$ARG" ]; then
		logb "\t\tOverclocking is enabled"
		WIFI_FIX=y
	fi
done
}

PATCHES=("${PATCHES[@]}" "check_wifi_fix_enabled")
