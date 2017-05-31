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

function print_start_build {
	if [ ${JOB_BUILD_NUMBER} -ge 1 ]; then
		logb "\n=================================================="
		logb "Build started on Jenkins on ${ROUTEID}.\n"
		logb "BUILDING #${JOB_BUILD_NUMBER} FROM ${USER}@${HOSTNAME}\n"
		logb "Release type: ${release_type} \n"
		arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
		logb "Archive prefix is: ${arc_name} \n"
		logb "Output Directory: ${OUTPUT_DIR}\n"
		logb "===================================================\n"

		if [ "$SILENT" -ne 1 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`

		link="http://grandprime.ddns.net/jenkins/"

		str_main="${dateStr}[${BUILD_TARGET}] ${distroTxt} ${ver} build %23${JOB_BUILD_NUMBER} started for device ${DEVICE_NAME} via Jenkins, running on ${USER}@${HOSTNAME}."
		textStr="${str_main}"

		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	   fi
	fi
}

function print_end_build {
	logb "Done."
	if [ "$SILENT" -ne 1 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`

		str_main="${dateStr}[${BUILD_TARGET}] ${distroTxt} ${ver} build %23${JOB_BUILD_NUMBER} for device ${DEVICE_NAME} on ${USER}@${HOSTNAME} completed successfully."
		textStr="${str_main}"

		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	fi
}
