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
BUILD_START_TIME=
function print_start_build {
	if [ "x${JOB_BUILD_NUMBER}" != "x" ] && [ ${JOB_BUILD_NUMBER} -ge 1 ]; then
		logb "\n==========================================================="
		logb "Build started on Jenkins on ${ROUTEID}.\n"
		logb "BUILDING #${JOB_BUILD_NUMBER} FROM ${USER}@${HOSTNAME}\n"
		logb "Release type: ${release_type} \n"
		arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
		logb "Archive prefix is: ${arc_name} \n"
		logb "Output Directory: ${OUTPUT_DIR}\n"
		logb "============================================================\n"

		if [ "x$SILENT" != "x1" ]; then
			dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`


			BUILD_START_TIME=$( date +%s)
			textStr="${dateStr}[${BUILD_TARGET}] ${distroTxt} ${ver} build %23${JOB_BUILD_NUMBER} started for device ${DEVICE_NAME} via Jenkins, running on ${USER}@${HOSTNAME}."

			print_to_telegram $textStr
		fi
	fi
}

function print_end_build {
	logb "Done."
	if [ "x$SILENT" != "x1" ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`

		link="${BUILD_URL}/artifact"

		END_TIME=$( date +%s )
		buildTime="%0ABuild time: $(format_time ${END_TIME} ${BUILD_START_TIME})"
		totalTime="%0ATotal time: $(format_time ${END_TIME} ${START_TIME})"


		if [ "x$BUILD_URL" != "x" ]; then
			arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
			rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
			bimg_name=bootimage-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}

			if [ "$BUILD_TARGET" == "recoveryimage" ]; then
				str_rec="%0ARecovery: ${link}/builds/recovery/${DEVICE_NAME}/${rec_name}.tar"
			elif [ "$BUILD_TARGET" == "bootimage" ]; then
				str_boot="%0ABoot image: ${link}/builds/boot/${DEVICE_NAME}/${bimg_name}.tar"
			elif [ "$BUILD_TARGET" == "otapackage" ]; then
				str_rom="%0A ROM: ${link}/builds/full/${arc_name}.zip"
				str_rec="%0A Recovery: ${link}/builds/recovery/${DEVICE_NAME}/${rec_name}.tar"
			fi
			str_changelog="%0AChangelog: ${link}/builds/full/chagelog-${arc_name}.txt"
			str_blurb="%0A%0AYou can flash boot/recovery images using ODIN or you can extract them using 7zip or tar under Linux and flash using TWRP."
		fi

		str_main="${dateStr}[${BUILD_TARGET}] ${distroTxt} ${ver} build %23${JOB_BUILD_NUMBER} for device ${DEVICE_NAME} on ${USER}@${HOSTNAME} completed successfully."
		textStr="${str_main}${str_rom}${str_rec}${str_boot}${str_changelog}${str_blurb}${buildTime}${totalTime}"

		print_to_telegram $textStr
	fi
}
