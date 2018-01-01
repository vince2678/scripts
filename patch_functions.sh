#!/bin/bash
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


function apply_repo_map {
	echoTextBold "Applying custom repository branch maps.."
	count=0
	for ix in `seq 0 $((${#REPO_REF_MAP[@]}-1))`; do
		count=$((count+1))
		repo=`echo ${REPO_REF_MAP[$ix]} | cut -d ':' -f 1`
		ref=`echo ${REPO_REF_MAP[$ix]} | cut -d ':' -f 2`

		if [ -d "${BUILD_TOP}/$repo" ]; then
			local GIT="git -C ${BUILD_TOP}/$repo"

			echoTextBlue "Repo is $repo. Reverting..."
			cd ${BUILD_TOP} && repo sync $repo -d

			echoTextBlue "Deleting branch $ref."
			${GIT} branch -D $ref 2>/dev/null

			echoTextBlue "Removing rogue patches in $repo..."
			${GIT} diff | patch -Rp1
			echoTextBlue "Fetching and checking out ref $ref..."
			${GIT} fetch $($GIT remote show|head -1) $ref:$ref && ${GIT} checkout $ref || exit_error $?
		else
			echoTextRed "Directory $repo does not exist!!"
			exit_error 1
		fi
		echo
	done

	if [ $count -eq 0 ]; then
		echoTextBold "No branch maps to apply."
	fi
}

function reverse_repo_map {
	echoTextBold "Reversing custom repository branch maps.."
	count=0
	for ix in `seq 0 $((${#REPO_REF_MAP[@]}-1))`; do
		count=$((count+1))
		repo=`echo ${REPO_REF_MAP[$ix]} | cut -d ':' -f 1`
		ref=`echo ${REPO_REF_MAP[$ix]} | cut -d ':' -f 2`

		if [ -d "${BUILD_TOP}/$repo" ]; then
			local GIT="git -C ${BUILD_TOP}/$repo"

			echoTextBlue "Repo is $repo.\n Reverting..."
			cd ${BUILD_TOP} && repo sync $repo -d

			echoTextBlue "Deleting branch $ref."
			${GIT} branch -D $ref 2>/dev/null

			echoTextBlue "Removing rogue patches in $repo..."
			${GIT} diff | patch -Rp1
		fi
		echo
	done

	if [ $count -eq 0 ]; then
		echoTextBold "No branch maps to apply."
	fi
}
