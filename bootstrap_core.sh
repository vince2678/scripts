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
	${CC} ${CMD_HELPER_SRC} -o ${CMD_HELPER} 2>/dev/null

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
