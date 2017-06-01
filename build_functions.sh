#! /bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function make_targets {
	#start building
	if [ "x$ver" == "x13.0" ]; then
		exit_on_failure make -j${JOB_NUMBER} $BUILD_TARGET CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA13/api"
	elif [ "x$ver" == "x14.1" ]; then
		exit_on_failure make -j${JOB_NUMBER} $BUILD_TARGET CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA14/api"
	else
		exit_on_failure make -j${JOB_NUMBER} $BUILD_TARGET CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA/api"
	fi
	#build su
	#if [ $ver == "13.0" ] && [ "$BUILD_TARGET" != "recoveryimage" ] && [ "$BUILD_TARGET" != "bootimage" ]; then
		#exit_on_failure make -j${JOB_NUMBER} addonsu
	#fi
}

function generate_changes {
	logb "Generating changes..."

	#get the date of the most recent build
	dates=($(ls ${BUILD_WWW_MOUNT_POINT}/builds/full/${DISTRIBUTION}-${ver}-*-${DEVICE_NAME}.zip 2>/dev/null | cut -d '-' -f 3 | sort -r))

	# use a preset time if we couldn't get the archive times.
	if [ -z $dates ]; then
		dates=20170430
	fi

	cd ${platform_common_dir}

	echo -e "\nMSM8916-COMMON\n---------\n" >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

	git log --decorate=full \
		--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

	cd ${ANDROID_BUILD_TOP}/kernel/${vendors[0]}/${kernel_name}

	echo -e "\nKERNEL\n---------\n" >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

	git log --decorate=full \
		--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

	if [ "x$BUILD_TARGET" == "xotapackage" ]; then
		#generate the changes
		cd ${ANDROID_BUILD_TOP}/device/${vendors[0]}/${DEVICE_NAME}

		echo -e "DEVICE\n---------\n" > ${OUTPUT_DIR}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

		cd ${common_dir}

		echo -e "\nDEVICE-COMMON\n---------\n" >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

		cd ${ANDROID_BUILD_TOP}/vendor/${vendors[0]}/${DEVICE_NAME}

		echo -e "\nVENDOR\n---------\n" >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${OUTPUT_DIR}/builds/full/${arc_name}.txt
	fi
}

