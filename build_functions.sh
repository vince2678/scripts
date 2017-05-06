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

function main {
	#move into the build dir
	cd $build_top
	#get the platform version
	platorm_version=$(grep 'PLATFORM_VERSION :' build/core/version_defaults.mk  | cut -d '=' -f 2)
	export WITH_SU
	if [ $platorm_version == "7.1.1" ] || [ $platorm_version == "7.1.2" ]; then
		export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4g"
		if [ "$distro" == "lineage" ]; then
			ver="14.1"
			distroTxt="LineageOS"
		elif [ "$distro" == "cm" ]; then
			ver="14.1"
			distroTxt="CyanogenMod"
		elif [ "$distro" == "omni" ]; then
			ver="7.1"
			distroTxt="Omni"
		else
			logr "Error: Unrecognised distro"
			exit_error 1
		fi
	elif [ $platorm_version == "6.0.1" ]; then
		if [ "$distro" == "lineage" ]; then
			ver="13.0"
			distroTxt="LineageOS"
		elif [ "$distro" == "cm" ]; then
			ver="13.0"
			distroTxt="CyanogenMod"
		elif [ "$distro" == "omni" ]; then
			ver="6.0"
			distroTxt="Omni"
		else
			logr "Error: Unrecognised distro"
			exit_error 1
		fi
	elif [ $platorm_version == "5.1.1" ]; then

		if [ "$distro" == "cm" ]; then
			ver="12.1"
			distroTxt="CyanogenMod"
		elif [ "$distro" == "omni" ]; then
			ver="5.1"
			distroTxt="Omni"
		else
			logr "Error: Unrecognised distro"
			exit_error 1
		fi

	elif [ $platorm_version == "5.0.2" ]; then

		if [ "$distro" == "cm" ]; then
			ver="12.0"
			distroTxt="CyanogenMod"
		elif [ "$distro" == "omni" ]; then
			ver="5.0"
			distroTxt="Omni"
		else
			logr "Error: Unrecognised distro"
			exit_error 1
		fi

	fi

	#set the recovery type
	recovery_variant=$(grep RECOVERY_VARIANT ${platform_common_dir}/BoardConfigCommon.mk | sed s'/ //'g)
	# get the release type
	if [ "${release_type}" == "" ]; then
		release_type=$(grep "CM_BUILDTYPE" ${common_dir}/${distro}.mk | cut -d'=' -f2 | sed s'/ //'g)
	fi

	# check if it was succesfully set, and set it to the default if not
	if [ "${release_type}" == "" ]; then
		release_type="NIGHTLY"
	fi

	# get the recovery type
	if [ "$recovery_variant" == "RECOVERY_VARIANT:=twrp" ]; then
		if [ "$ver" == "7.1" ]; then
			recovery_flavour="TWRP-3.1.x"
		elif [ "$ver" == "6.0" ]; then
			recovery_flavour="TWRP-3.0.x"
		else
			recovery_flavour="TWRP-2.8.7.0"
		fi
	elif [ "$distro" == "lineageos" ] || [ "$distro" == "lineage" ]; then
		recovery_flavour="LineageOSRecovery"
	elif [ "$distro" == "cm" ]; then
		recovery_flavour="CyanogenModRecovery"
	elif [ "$distro" == "omni" ]; then
		if [ "$ver" == "7.1" ]; then
			recovery_flavour="TWRP-3.1.x"
		elif [ "$ver" == "6.0" ]; then
			recovery_flavour="TWRP-3.0.x"
		else
			recovery_flavour="TWRP-2.8.7.0"
		fi
	fi

	#set up the environment
	. build/envsetup.sh

	# remove duplicate crypt_fs.
	if [ -d ${build_top}/device/qcom-common/cryptfs_hw ] && [ -d ${build_top}/vendor/qcom/opensource/cryptfs_hw ]; then
		rm -r ${build_top}/vendor/qcom/opensource/cryptfs_hw
	fi

	#select the device
	lunch ${distro}_${device_name}-${build_type}

	# exit if there was an error
	exit_error $?

	#create the directories
	mkdir ${BUILD_TEMP}/ -p
	mkdir ${out_dir}/builds/boot -p
	mkdir ${out_dir}/builds/boot/${device_name} -p
	mkdir ${out_dir}/builds/full -p
	mkdir ${out_dir}/builds/odin -p
	mkdir ${out_dir}/builds/recovery -p
	mkdir ${out_dir}/builds/recovery/${device_name} -p
	mkdir ${out_dir}/builds/su -p
}

function make_targets {
	#start building
	if [ $ver == "13.0" ]; then
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA13/api"
	elif [ $ver == "14.1" ]; then
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA14/api"
	else
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA/api"
	fi
	#cowardly exit 1 if we fail.
	exit_error $?
	#build su
	#if [ $ver == "13.0" ] && [ "$target" != "recoveryimage" ] && [ "$target" != "bootimage" ]; then
		#make -j${job_num} addonsu
		#cowardly exit 1 if we fail.
		#exit_error $?
	#fi
}

function generate_changes {
	logb "Generating changes..."

	#get the date of the most recent build
	dates=($(ls ${BUILD_WWW_MOUNT_POINT}/builds/full/${distro}-${ver}-*-${device_name}.zip 2>/dev/null | cut -d '-' -f 3 | sort -r))

	# use a preset time if we couldn't get the archive times.
	if [ -z $dates ]; then
		dates=20170201
	fi

	if [ "$target" == "otapackage" ]; then
		#generate the changes
		cd ${ANDROID_BUILD_TOP}/device/${vendors[0]}/${device_name}

		echo -e "DEVICE\n---------\n" > ${out_dir}/builds/full/${arc_name}.txt

		git log --stat --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${common_dir}

		echo -e "\nDEVICE-COMMON\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --stat --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${ANDROID_BUILD_TOP}/vendor/${vendors[0]}/${device_name}

		echo -e "\nVENDOR\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --stat --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${ANDROID_BUILD_TOP}/vendor/${vendors[1]}/binaries

		echo -e "\nVENDOR BINARIES\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --stat --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt
	fi

	cd ${platform_common_dir}

	echo -e "\nMSM8916-COMMON\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

	git log --stat --decorate=full \
		--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

	cd ${ANDROID_BUILD_TOP}/kernel/${vendors[0]}/${kernel_name}

	echo -e "\nKERNEL\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

	git log --stat --decorate=full \
		--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt
}

