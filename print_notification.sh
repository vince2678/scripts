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
	if [ ${build_num} -ge 1 ]; then
		logb "\n=================================================="
		logb "Build started on Jenkins on ${ROUTEID}.\n"
		logb "BUILDING #${build_num} FROM ${USER}@${HOSTNAME}\n"
		logb "Release type: ${release_type} \n"
		arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		logb "Archive prefix is: ${arc_name} \n"
		logb "Output Directory: ${out_dir}\n"
		logb "===================================================\n"

		if [ $silent -eq 0 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`

		link="http://grandprime.ddns.net/jenkins/"#?ROUTEID=${ROUTEID}"

		str_main="${dateStr}[${target}] ${distroTxt} ${ver} build %23${build_num} started for device ${device_name} via Jenkins, running on ${USER}@${HOSTNAME}."
		#str_blurb="%0A%0A This build is running on Jenkins instance ${ROUTEID}, accessible at ${link}"
		textStr="${str_main}${str_blurb}"

		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	   fi
	fi
}

function print_end_build {
	logb "Done."
	if [ $silent -eq 0 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`
		target_str_len=$(echo ${BUILD_JENKINS_MOUNT_POINT} | wc -c)
		link="http://grandprime.ddns.net/jenkins/job/Omni_Builds/job/${JOB_BASE_NAME}/${build_num}/artifact"

		arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		rec_name=${recovery_flavour}-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
		bimg_name=bootimage-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}

		if [ "$target" == "recoveryimage" ]; then
			str_rec="%0ARecovery: ${link}/builds/recovery/${device_name}/${rec_name}.tar"
		elif [ "$target" == "bootimage" ]; then
			str_boot="%0ABoot image: ${link}/builds/boot/${device_name}/${bimg_name}.tar"
		elif [ "$target" == "otapackage" ]; then
			str_rom="%0A ROM: ${link}/builds/full/${arc_name}.zip"
			if [ $ver == "13.0" ]; then
				str_su="%0A SU: ${link}/builds/su/addonsu-arm_j${build_num}.zip"
			fi
			str_rec="%0A Recovery: ${link}/builds/recovery/${device_name}/${rec_name}.tar"
		fi
		str_main="${dateStr}[${target}] ${distroTxt} ${ver} build %23${build_num} for device ${device_name} on ${USER}@${HOSTNAME} completed successfully."
		str_blurb="%0A%0AYou can flash boot/recovery images using ODIN or you can extract them using 7zip or tar under Linux and flash using TWRP."
		str_changelog="%0AChangelog: ${link}/builds/full/${arc_name}.txt"
		textStr="${str_main}${str_rom}${str_su}${str_rec}${str_boot}${str_changelog}${str_blurb}"

		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	fi
}
