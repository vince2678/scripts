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

function rsync_cp {
	if [ "x${SYNC_HOST}" == "x" ]; then
		exit_on_failure rsync -av -P $1 $2
	else
		exit_on_failure ssh -o StrictHostKeyChecking=no ${SYNC_HOST} mkdir -p $(dirname $2)
		exit_on_failure rsync -av -P -e "ssh -o StrictHostKeyChecking=no" $1 ${SYNC_HOST}:$2
	fi
}

function copy_recoveryimage {
	if [ -e ${ANDROID_PRODUCT_OUT}/recovery.img ]; then
		#copy the recovery image
		cp ${ANDROID_PRODUCT_OUT}/recovery.img $BUILD_TEMP
		cd $BUILD_TEMP
		#archive the image
		#define some variables
		if [ -z ${JOB_BUILD_NUMBER} ]; then
			rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}-$(date +%Y%m%d)-${DEVICE_NAME}
		else
			rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
		fi

		logb "\n\t\tCopying recovery image...\n"
		tar cf ${rec_name}.tar recovery.img
		exit_on_failure rsync -v -P ${rec_name}.tar ${OUTPUT_DIR}/builds/recovery/${DEVICE_NAME}/${rec_name}.tar
	fi
}

function copy_otapackage {
	if [ "x$BUILD_TARGET" == "xotapackage" ]; then
		ota_out=${DISTRIBUTION}_${DEVICE_NAME}-ota-${BUILD_NUMBER}.zip
		if ! [ -e ${ANDROID_PRODUCT_OUT}/${ota_out} ]; then
			logb "\nSearching for OTA package..."
			ota_out=`basename $(find ${ANDROID_PRODUCT_OUT} -maxdepth 1 -type f -name '*zip' | head -1) 2>/dev/null`

			if [ "x$ota_out" == "x" ]; then
				echoText "Failed to find ota package!!"
				exit_error 1
			fi
		fi
		logb "\nFound ota package $ota_out"

		#define some variables
		if [ "x${JOB_BUILD_NUMBER}" == "x" ]; then
			rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}-${DEVICE_NAME}
			arc_name=${DISTRIBUTION}-${ver}-$(date +%Y%m%d)-${release_type}-${DEVICE_NAME}
		else
			rec_name=${recovery_flavour}-${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${DEVICE_NAME}
			arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
		fi

		#check if our correct binary exists
		if [ -e ${BUILD_TOP}/META-INF ]; then
			ota_bin="META-INF/com/google/android/update-binary"

			logb "\t\tFound update binary..."
			cp -dpR ${BUILD_TOP}/META-INF $BUILD_TEMP/META-INF
			cp -ndpR ${BUILD_TOP}/META-INF ./
			#delete the old binary
			logb "\t\tPatching zip file unconditionally..."
			zip -d ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
			zip -ur ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
		fi

		#copy the zip in the background
		logb "\n\t\tCopying zip image..."

		# don't copy in the backgroud if we're not making the ODIN archive as well.
		exit_on_failure rsync -v -P ${ANDROID_PRODUCT_OUT}/${ota_out} ${OUTPUT_DIR}/builds/full/${arc_name}.zip

		#calculate md5sums
		md5sums=$(md5sum ${ANDROID_PRODUCT_OUT}/${ota_out} | cut -d " " -f 1)

		echo "${md5sums} ${arc_name}.zip" > ${OUTPUT_DIR}/builds/full/${arc_name}.zip.md5 || exit_error 1
	fi
}


function copy_supackage {
	if [ -e ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ]; then
		logb "\n\t\tCopying su image..."
		exit_on_failure rsync -v -P ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ${OUTPUT_DIR}/builds/su/addonsu-arm_j${JOB_BUILD_NUMBER}.zip
	elif [ -e ${ANDROID_PRODUCT_OUT}/addonsu-${ver}-arm.zip ]; then
		logb "\n\t\tCopying su image..."
		exit_on_failure rsync -v -P ${ANDROID_PRODUCT_OUT}/addonsu-${ver}-arm.zip ${OUTPUT_DIR}/builds/su/addonsu-${ver}-arm_j${JOB_BUILD_NUMBER}.zip
	fi
}

function copy_odin_package {
	if [ "x$MAKE_ODIN_PACKAGE" == "x1" ]; then
		#define some variables
		if [ "x${JOB_BUILD_NUMBER}" == "x" ]; then
			arc_name=${DISTRIBUTION}-${ver}-$(date +%Y%m%d)-${release_type}-${DEVICE_NAME}
		else
			arc_name=${DISTRIBUTION}-${ver}_j${JOB_BUILD_NUMBER}_$(date +%Y%m%d)_${release_type}-${DEVICE_NAME}
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
		logb "\n\t\tCompressing ODIN-flashable image..."

		#compress the image
		exit_on_failure 7z a ${arc_name}.tar.md5.7z ${arc_name}.tar.md5

		logb "\n\t\tCopying ODIN-flashable compressed image..."
		#copy it to the output dir
		exit_on_failure rsync -v -P  ${arc_name}.tar.md5.7z ${OUTPUT_DIR}/builds/odin/
	fi
}

COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_recoveryimage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_otapackage")
#COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_supackage")
COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_odin_package")

function copy_files {
	for ix in `seq 0 $((${#COPY_FUNCTIONS[@]}-1))`; do
		echoTextBlue "Running function ${COPY_FUNCTIONS[$ix]}"
		${COPY_FUNCTIONS[$ix]} $@
	done
}
