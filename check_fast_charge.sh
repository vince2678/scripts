#!/bin/bash

function check_fast_charge_enabled {
ARG="--fast-charge"
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "$ARG" ]; then
		logb "\t\tFast charging is enabled"
		FAST_CHARGING=y
	fi
done
}

PATCHES=("${PATCHES[@]}" "check_fast_charge_enabled")
