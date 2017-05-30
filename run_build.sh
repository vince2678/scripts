#! /bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

############
#		  #
#  COLORS  #
#		  #
############
START_TIME=$( date +%s )

BOLD="\033[1m"
GREEN="\033[01;32m"
RED="\033[01;31m"
RESTORE="\033[0m"
NC='\033[0m' # No Color
BLUE='\033[1;35m'

# create a temprary working dir
BUILD_TEMP=$(mktemp -d)

CURL="curl -connect-timeout=10"

# file extraction function names
PRE_PATCH_FUNCTIONS=();
PATCH_FUNCTIONS=();

COPY_FUNCTIONS=();
POST_COPY_FUNCTIONS=();

url="https://raw.githubusercontent.com/vince2678/build_script/master"

kernel_dir=kernel/samsung/msm8916

SILENT=0

function logr {
	echo -e ${RED} "$@" ${NC}
}

function logb {
	echo -e ${BLUE} "$@" ${NC}
}

function log {
	echo -e "$@"
}

function validate_arg {
	valid=$(echo $1 | sed s'/^[\-][a-z0-9A-Z\-]*/valid/'g)
	[ "$valid" == "valid" ] && return 0 || return 1;
}

function print_help {
                log "Usage: `basename $0` [OPTION]\n";
                log "  -d, --distribution\tdistribution name\n" ;
                log "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" ;
                log "  -e, --type\twhere type is one of user|userdebug|eng\n" ;
                log "  -n, --device\tdevice name\n" ;
                log "  -p, --path\tbuild top path\n" ;
                log "  -o, --output\toutput path (path to jenkins archive dir)\n";
                log "\nOptional commands:\n";
                log "  -b\tbuild number\n";
                log "  -s, --silent\tdon't publish to Telegram\n";
                log "  -c, --odin\tbuild compressed (ODIN) images\n";
                log "  -r, --clean\tclean build directory on completion\n";
                log "  -a, --sync_all\tSync entire build tree\n";
                log "  -v, --sync\tSync device/kernel/vendor trees\n";
                log "  -u, --su\tAdd SU to build\n";
                log "  --update-script\tUpdate build script immediately\n";

                log "  -j\tnumber of parallel make jobs to run\n";

		exit
}
prev_arg=
for index in `seq 1 ${#}`; do
	nexti=$((index+1))

	# find arguments of the form --arg=val and split to --arg val
	if [ -n "`echo ${!index} | grep -o =`" ]; then
		cur_arg=`echo ${!index} | cut -d'=' -f 1`
		nextarg=`echo ${!index} | cut -d'=' -f 2`
	else
		cur_arg=${!index}
		nextarg=${!nexti}
	fi

	case $cur_arg in
		-a) SYNC_ALL=1 ;;
		-b) BUILD_NUMBER=$nextarg ;;
		-d) DISTRIBUTION=$nextarg ;;
		-e) BUILD_VARIANT=$nextarg ;;
		-j) JOB_NUMBER=$nextarg ;;
		-h) print_help ;;
		-n) DEVICE_NAME=$nextarg ;;
		-o) OUTPUT_DIR=$nextarg ;;
		-p) BUILD_TOP=`realpath $nextarg` ;;
		-r) CLEAN_TARGET_OUT=$nextarg ;;
		-s) SILENT=1 ;;
		-t) BUILD_TARGET=$nextarg ;;
		-u) WITH_SU=true ;;
		-v) SYNC_VENDOR=1 ;;
		-w)
		    logb "\t\tBuilding separate wlan module";
		    SEPARATE_WLAN_MODULE=y
		    ;;

		# long options
		--clean)    CLEAN_TARGET_OUT=$nextarg ;;
		--device)   DEVICE_NAME=$nextarg ;;
		--distro)   DISTRIBUTION=$nextarg ;;
		--experimental)
			logb "\t\tExperimental kernel is enabled"
			EXPERIMENTAL_KERNEL=y
			EXPERIMENTAL_BRANCH="cm-14.1-experimental"
			;;

		--help)     print_help ;;
		--jobs)     JOB_NUMBER=$nextarg ;;

		--oc)
			logb "\t\tExperimental kernel is enabled"
			EXPERIMENTAL_KERNEL=y
			EXPERIMENTAL_BRANCH="cm-14.1-experimental"
			;;

		--odin)     MAKE_ODIN_PACKAGE=1 ;;
		--output)   OUTPUT_DIR=$nextarg ;;
		--path)     BUILD_TOP=`realpath $nextarg` ; logr "Path is $BUILD_TOP";;
		--silent)   SILENT=1 ;;
		--su)       WITH_SU=true ;;
		--sync)     SYNC_VENDOR=1 ;;
		--sync-all) SYNC_ALL=1 ;;
		--sync_all) SYNC_ALL=1 ;;
		--target)   BUILD_TARGET=$nextarg ;;
		--type)     BUILD_VARIANT=$nextarg ;;
		--update-script)  UPDATE_SCRIPT=1;;
		--wifi-fix)
			logb "\t\tBuilding separate wlan module";
			SEPARATE_WLAN_MODULE=y
			;;

		*) validate_arg $cur_arg;
			if [ $? -eq 0 ]; then
				logr "Unrecognised option passed"
				print_help
			else
				validate_arg $prev_arg
				if [ $? -eq 1 ]; then
				logr "Argument passed without flag option"
					print_help
				fi
			fi
			;;
	esac
	prev_arg=$cur_arg
done

# fetch the critical build scripts
logb "Getting build script list..."
script_dir=${BUILD_TEMP}/scripts
file_list=$(${CURL} ${url}/list.txt 2>/dev/null)

if [ $? -ne 0 ]; then
	logr "Failed! Checking for local version.."
	file_list=$(cat $(dirname $0)/list.txt)
	if [ $? -ne 0 ]; then
		logr "Fatal! No local version found."
		exit 1
	fi
else
	${CURL} ${url}/list.txt 1>$(dirname $0)/list.txt 2>/dev/null
fi

mkdir -p ${script_dir}

# source the files
for source_file in ${file_list}; do
	${CURL} ${url}/${source_file} 1>${script_dir}/${source_file} 2>/dev/null

	if [ $? -eq 0 ]; then
		. ${script_dir}/${source_file}
		mv -f ${script_dir}/${source_file} $(dirname $0)/${source_file}
	else
		. $(dirname $0)/${source_file}
	fi
done

if [ -z "$UPDATE_SCRIPT" ]; then
	# save the patches
	extract_patches $@
	# setup env vars
	bootstrap "$@"
	# check if any other builds are running
	check_if_build_running
	# reverse any previously applied patch
	reverse_patch
	# get the platform info
	get_platform_info
	# sync the repos
	sync_vendor_trees "$@"
	sync_all_trees "$@"
	if [ `echo ${DEVICE_NAME}|wc -c` -gt 1 ]; then
		# apply the patch
		apply_patch
		# setup the build environment
		setup_env "$@"
		# print the build start text
		print_start_build
		# make the targets
		make_targets
		# copy the files
		copy_files
		# generate the changes
		generate_changes
		# end the build
		print_end_build
		# reverse any previously applied patch
		reverse_patch
	fi
fi
# sync the build script
sync_script "$@"
# copy the target
clean_target

END_TIME=$( date +%s )

# PRINT RESULT TO USER
echoText "SCRIPT COMPLETED!"
echo -e ${RED}"TIME: $(format_time ${END_TIME} ${START_TIME})"${RESTORE}; newLine
