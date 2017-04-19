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

function copy_recoveryimage {
	if [ -e ${ANDROID_PRODUCT_OUT}/recovery.img ]; then
		#copy the recovery image
		cp ${ANDROID_PRODUCT_OUT}/recovery.img $BUILD_TEMP
		cd $BUILD_TEMP
		#archive the image
		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=${recovery_flavour}-${distro}-${ver}-$(date +%Y%m%d)-${device_name}
		else
			rec_name=${recovery_flavour}-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
		fi

		logb "\t\tCopying recovery image..."
		tar cf ${rec_name}.tar recovery.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/recovery/${device_name}/${rec_name}.tar || exit 1
	fi
}

function copy_bootimage {
	if [ "$target" == "bootimage" ]; then

		#copy the boot image
		cp ${ANDROID_PRODUCT_OUT}/boot.img $BUILD_TEMP
		cd $BUILD_TEMP
		#archive the image
		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=bootimage-${distro}-${ver}-$(date +%Y%m%d)-${device_name}
		else
			rec_name=bootimage-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
		fi

		logb "\t\tCopying boot image..."
		tar cf ${rec_name}.tar boot.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/boot/${device_name}/${rec_name}.tar || exit 1
	fi
}

function copy_otapackage {
	ota_out=${distro}_${device_name}-ota-${BUILD_NUMBER}.zip
	if [ -e ${ANDROID_PRODUCT_OUT}/${ota_out} ]; then

		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=${recovery_flavour}-${distro}-${ver}-${device_name}
			arc_name=${distro}-${ver}-$(date +%Y%m%d)-${release_type}-${device_name}
		else
			rec_name=${recovery_flavour}-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
			arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		fi

		#check if our correct binary exists
		if [ -e ${build_top}/META-INF ]; then
			ota_bin="META-INF/com/google/android/update-binary"

			logb "\t\tFound update binary..."
			cp -dpR ${build_top}/META-INF $BUILD_TEMP/META-INF
			cp -ndpR ${build_top}/META-INF ./
			#delete the old binary
			logb "\t\tPatching zip file unconditionally..."
			zip -d ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
			zip -ur ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
		fi

		#copy the zip in the background
		logb "\t\tCopying zip image..."

		# don't copy in the backgroud if we're not making the ODIN archive as well.
		rsync -v -P ${ANDROID_PRODUCT_OUT}/${ota_out} ${out_dir}/builds/full/${arc_name}.zip || exit 1

		#calculate md5sums
		md5sums=$(md5sum ${ANDROID_PRODUCT_OUT}/${ota_out} | cut -d " " -f 1)

		echo "${md5sums} ${arc_name}.zip" > ${out_dir}/builds/full/${arc_name}.zip.md5  || exit 1 &

		exit_error $?
	fi
}


function copy_supackage {
	if [ -e ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ]; then
		logb "\t\tCopying su image..."
		rsync -v -P ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ${out_dir}/builds/su/addonsu-arm_j${build_num}.zip
	fi
}

function copy_odin_package {
	if [ ${with_odin} -eq 1 ]; then
		#define some variables
		if [ -z ${build_num} ]; then
			arc_name=${distro}-${ver}-$(date +%Y%m%d)-${release_type}-${device_name}
		else
			arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		fi

		cd ${ANDROID_PRODUCT_OUT}

		# rename the system image
		ln system.img system.img.ext4

		#pack the image
		tar -H ustar -c boot.img recovery.img system.img.ext4 -f ${BUILD_TEMP}/${arc_name}.tar

		# remove the system image
		rm system.img.ext4

		cd $BUILD_TEMP
		#calculate the md5sum
		md5sum -t ${arc_name}.tar >> ${arc_name}.tar
		mv -f ${arc_name}.tar ${arc_name}.tar.md5
		logb "\t\tCompressing ODIN-flashable image..."

		#compress the image
		7z a ${arc_name}.tar.md5.7z ${arc_name}.tar.md5

		# exit if there was an error
		exit_error $?

		logb "\t\tCopying ODIN-flashable compressed image..."
		#copy it to the output dir
		rsync -v -P  ${arc_name}.tar.md5.7z ${out_dir}/builds/odin/

		# exit if there was an error
		exit_error $?
	fi
}

COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_recoveryimage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_bootimage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_otapackage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_supackage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_odin_package")

function copy_files {
	for ix in `seq 0 $((${#COPY_FUNCTIONS[@]}-1))`; do
		logr "\tRunning function ${COPY_FUNCTIONS[$ix]}"
		${COPY_FUNCTIONS[$ix]} $@
	done
}
