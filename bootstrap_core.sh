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

# declare globals for argv helper
CC="gcc --std=c99"

# declare some globals
build_top=
release_type=""
ver=""
distroTxt=""
recovery_variant=""
platform_common_dir=""
common_dir=""
recovery_flavour=""

kernel_name="msm8916"
vendors[0]="samsung"
vendors[1]="qcom"

function bootstrap {

	# make the target
	${CC} ${CMD_HELPER_SRC} -o ${CMD_HELPER} 1>/dev/null

	# exit if we couldn't compile the code
	if [ $? != "0" ]; then
		rm -rf ${CMD_HELPER} ${CMD_HELPER_SRC} ${BUILD_TEMP}
		exit 1
	fi

	# loop variables
	arg_count=${#BASH_ARGV[@]}
	arg_string=""
	index=0
	# arguments are reversed, so let's flip them around
	while [ "$index" -lt "$arg_count" ]; do
		arg_string="${BASH_ARGV[$index]} ${arg_string}"
		((index=index+1))
	done

	# run the getopt helper
	CMD_OUT=`$CMD_HELPER ${arg_string}`

	# exit if we didn't read any commands.
	if [ $? != "0" ]; then
		rm -rf ${CMD_HELPER} ${CMD_HELPER_SRC} ${BUILD_TEMP}
		exit 1
	fi

	#source and remove the source and binary file
	. $CMD_OUT
	rm ${CMD_HELPER} ${CMD_HELPER_SRC} ${CMD_OUT}

	build_top=`realpath $android_top`

	# set the common dir
	platform_common_dir="$build_top/device/${vendors[0]}/msm8916-common/"
	if [ "$(echo $device_name | cut -c -3)" == "gte" ]; then
		common_dir="$build_top/device/${vendors[0]}/gte-common/"
	elif [ "$(echo $device_name | cut -c -2)" == "j5" ]; then
		common_dir="$build_top/device/${vendors[0]}/j5-common/"
	else
		common_dir="$build_top/device/${vendors[0]}/gprimelte-common/"
	fi

	#setup the path
	if [ -n ${BUILD_BIN_ROOT} ]; then
		export PATH=$PATH:${BUILD_BIN_ROOT}
	fi
}

function get_platform_info {
	#move into the build dir
	cd $build_top
	#get the platform version
	platform_version=$(grep 'PLATFORM_VERSION[ ]*:' build/core/version_defaults.mk  | cut -d '=' -f 2)
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
}

function setup_env {

	#move into the build dir
	cd $build_top

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
	mkdir ${out_dir}/builds/full -p
	mkdir ${out_dir}/builds/odin -p
	mkdir ${out_dir}/builds/recovery -p
	mkdir ${out_dir}/builds/recovery/${device_name} -p
	mkdir ${out_dir}/builds/su -p
}
