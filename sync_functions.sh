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
	if [ ${sync_vendor} -eq 1 ]; then
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
					repo sync ${dir}/${vendor}/${i} --force-sync
				done
			done
		done
	fi
}

function sync_all_trees {
	if [ ${sync_all} -eq 1 ]; then
		logb "Syncing all trees..."
		cd ${build_top}
		repo sync --force-sync
		cd $OLDPWD
	fi
}

function sync_script {
	logb "Updating build script..."
	${CURL} ${url}/$(basename $0) | tee $0 > /dev/null
	logb "Done."
}