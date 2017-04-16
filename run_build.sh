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

#colours
RED='\033[1;31m'
BLUE='\033[1;35m'
NC='\033[0m' # No Color

# create a temprary working dir
BUILD_TEMP=$(mktemp -d)

CURL="curl -connect-timeout=20"

# file extraction function names
PATCHES=();
FUNCTION_QUEUE=();

url="https://raw.githubusercontent.com/vince2678/build_script/master"

function logr {
	echo -e ${RED} "$@" ${NC}
}

function logb {
	echo -e ${BLUE} "$@" ${NC}
}

function log {
	echo "$@"
}

# fetch the critical build scripts
logb "Getting build script list..."
script_dir=${BUILD_TEMP}/scripts
file_list=$(${CURL} ${url}/list.txt 2>/dev/null)

if [ $? -ne 0 ]; then
	logr "Failed! Checking for local version.."
	file_list=$(cat $(dirname $0)/list.txt)
fi

mkdir -p ${script_dir}

# source the files
for source_file in ${file_list}; do
	${CURL} ${url}/${source_file} 1>${script_dir}/${source_file} 2>/dev/null

	if [ $? -eq 0 ]; then
		. ${script_dir}/${source_file}
		mv ${script_dir}/${source_file} $(dirname $0)/${source_file}
	else
		. $(dirname $0)/${source_file}
	fi
done

# save the patches
extract_patches $@
# setup env vars
bootstrap "$@"
# check if any other builds are running
check_if_build_running
# reverse any previously applied patch
reverse_patch
# sync the repos
sync_vendor_trees
sync_all_trees
if [ "${distro}" != "" ]; then
	# apply the patch
	apply_patch
	# run the main function
	main "$@"
	# print the build start text
	print_start_build
	# make the targets
	make_targets
	# copy the files
	move_files
	# end the build
	print_end_build
	# reverse any previously applied patch
	reverse_patch
fi
# sync the build script
sync_script "$@"
# copy the target
clean_target
