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

function sync_vendor_trees {
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "--sync" ] || [ "${!i}" == "-v" ]; then
		SYNC=1
		logb "Syncing vendor trees..."
		cd ${build_top}
		for vendor in ${vendors[*]}; do
			targets="device vendor kernel"
			for dir in ${targets}; do
				if ! [ -d ${dir}/${vendor} ]; then continue; fi
				cd ${dir}/${vendor}/
				devices=`ls`
				cd ${build_top}
				for i in ${devices}; do
					repo sync ${dir}/${vendor}/${i} --force-sync --prune
				done
			done
		done
	fi
done
}

function sync_all_trees {
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "--sync_all" ] || [ "${!i}" == "-a" ] || [ "${!i}" == "--sync-all" ]; then
		SYNC=1
		logb "Syncing all trees..."
		cd ${build_top}

		# sync substratum if we're on LOS 14.1
		if [ "$ver" == "14.1" ]; then
			unsync_substratum
		fi

		repo sync --force-sync --prune

		# sync substratum if we're on LOS 14.1
		if [ "$ver" == "14.1" ]; then
			sync_substratum
		fi

		cd $OLDPWD
	fi
done
}

function sync_script {
	logb "Updating build script..."
	${CURL} ${url}/$(basename $0) | tee $0 > /dev/null
	logb "Done."
}
