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

PATCH_DIR=$BUILD_TEMP/patches

function extract_patches {
	mkdir -p ${PATCH_DIR}

	for ix in `seq 0 $((${#PATCHES[@]}-1))`; do
		logr "Running function ${PATCHES[$ix]}"
		${PATCHES[$ix]} $@
	done
}

function apply_patch {
	if ! [ -e ${build_top}/.patched ]; then
		logb "Patching build top..."
		cd ${build_top}

		count=0

		for patch_file in $(find ${platform_common_dir}/patch/ -type f 2>/dev/null); do
			# test applying the patch
			cat ${patch_file} | patch -p1 --dry-run

			if [ $? -eq 0 ]; then
				cat  ${patch_file} | patch -p1
				count=$(($count+1))
			else
				logr "Failed to apply patch ${patch_file}! Fix this."
			fi
		done

		for patch_file in $(find ${PATCH_DIR} -type f 2>/dev/null); do
			# test applying the patch
			cat ${patch_file} | patch -p1 --dry-run

			if [ $? -eq 0 ]; then
				cat ${patch_file} | patch -p1
				count=$(($count+1))
			else
				logr "Failed to apply patch ${patch_file}! Fix this."
			fi
		done

		if [ ${count} -eq 0 ]; then
			logb "Nothing to patch."
		else
			touch ${build_top}/.patched
			logb "Done."
		fi

		logb "Replacing ld.gold ..."
		for ld_bin in $(ls prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.1*/x86_64-linux/bin/ld); do
			cp ${ld_bin} ${ld_bin}.old
			cp $(which ld.gold) $ld_bin
		done

		logb "Done."
		cd $OLDPWD
	fi
}

function reverse_patch {
	if [ -e ${build_top}/.patched ]; then
		logb "Unpatching build top..."
		cd ${build_top}
		count=0

		for patch_file in $(find ${platform_common_dir}/patch/ -type f 2>/dev/null); do
			# test applying the patch
			cat ${patch_file} | patch -Rp1 --dry-run

			if [ $? -eq 0 ]; then
				cat ${patch_file} | patch -Rp1
				count=$(($count+1))
			else
				logr "Failed to apply patch ${patch_file}! Fix this."
			fi
		done

		for patch_file in $(find ${PATCH_DIR} -type f 2>/dev/null); do
			# test applying the patch
			cat  ${patch_file} | patch -Rp1 --dry-run

			if [ $? -eq 0 ]; then
				cat ${patch_file} | patch -Rp1
				count=$(($count+1))
			else
				logr "Failed to apply patch ${patch_file}! Fix this."
			fi
		done

		if [ ${count} -eq 0 ]; then
			logb "Nothing to patch."
		else
			rm ${build_top}/.patched
			logb "Done."
		fi

		logb "Replacing ld.gold ..."
		for ld_bin in $(ls prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.1*/x86_64-linux/bin/ld); do
			cp ${ld_bin}.old ${ld_bin}
			rm ${ld_bin}.old -f
		done
		logb "Done."
		cd $OLDPWD
	fi
}

