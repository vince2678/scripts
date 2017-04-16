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

function main {
	#move into the build dir
	cd $build_top
	#get the platform version
	platorm_version=$(grep 'PLATFORM_VERSION :' build/core/version_defaults.mk  | cut -d '=' -f 2)
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
	mkdir ${out_dir}/builds/boot/${device_name} -p
	mkdir ${out_dir}/builds/full -p
	mkdir ${out_dir}/builds/odin -p
	mkdir ${out_dir}/builds/recovery -p
	mkdir ${out_dir}/builds/recovery/${device_name} -p
	mkdir ${out_dir}/builds/su -p
}

function make_targets {
	#start building
	if [ $ver == "13.0" ]; then
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA13/api"
	elif [ $ver == "14.1" ]; then
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA14/api"
	else
		make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA/api"
	fi
	#cowardly exit 1 if we fail.
	exit_error $?
	#build su
	if [ $ver == "13.0" ] && [ "$target" != "recoveryimage" ] && [ "$target" != "bootimage" ]; then
		make -j${job_num} addonsu
		#cowardly exit 1 if we fail.
		exit_error $?
	fi
}

function move_files {

	if [ "$target" == "recoveryimage" ]; then

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

		logb "Copying recovery image..."
		tar cf ${rec_name}.tar recovery.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/recovery/${device_name}/${rec_name}.tar || exit 1

	elif [ "$target" == "bootimage" ]; then

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

		logb "Copying boot image..."
		tar cf ${rec_name}.tar boot.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/boot/${device_name}/${rec_name}.tar || exit 1

	elif [ "$target" == "otapackage" ]; then

		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=${recovery_flavour}-${distro}-${ver}-${device_name}
			arc_name=${distro}-${ver}-$(date +%Y%m%d)-${release_type}-${device_name}
		else
			rec_name=${recovery_flavour}-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
			arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		fi

		logb "Copying files..."
		#move into the build dir
		#copy the images
		cp ${ANDROID_PRODUCT_OUT}/boot.img $BUILD_TEMP
		cp ${ANDROID_PRODUCT_OUT}/recovery.img $BUILD_TEMP
		cp ${ANDROID_PRODUCT_OUT}/system.img $BUILD_TEMP/system.img.ext4

		cd $BUILD_TEMP

		logb "Copying recovery image..."
		tar cf ${rec_name}.tar recovery.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/recovery/${device_name}/${rec_name}.tar || exit 1

		if [ $ver == "13.0" ]; then
			logb "Copying su image..."
			rsync -v -P ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ${out_dir}/builds/su/addonsu-arm_j${build_num}.zip
		fi

		ota_out=${distro}_${device_name}-ota-${BUILD_NUMBER}.zip
		#check if our correct binary exists
		logb "Locating update binary..."
		if [ -e ${build_top}/META-INF ]; then
			ota_bin="META-INF/com/google/android/update-binary"

			logb "Found update binary..."
			cp -dpR ${build_top}/META-INF $BUILD_TEMP/META-INF
			cp -ndpR ${build_top}/META-INF ./
			#delete the old binary
			logb "Patching zip file unconditionally..."
			zip -d ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
			zip -ur ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
		fi

		#copy the zip in the background
		logb "Copying zip image..."

		# don't copy in the backgroud if we're not making the ODIN archive as well.
		if [ ${with_odin} -eq 1 ]; then
			rsync -v -P ${ANDROID_PRODUCT_OUT}/${ota_out} ${out_dir}/builds/full/${arc_name}.zip || exit 1 &
		else
			rsync -v -P ${ANDROID_PRODUCT_OUT}/${ota_out} ${out_dir}/builds/full/${arc_name}.zip || exit 1
		fi

			#calculate md5sums
			md5sums=$(md5sum ${ANDROID_PRODUCT_OUT}/${ota_out} | cut -d " " -f 1)

			echo "${md5sums} ${arc_name}.zip" > ${out_dir}/builds/full/${arc_name}.zip.md5  || exit 1 &

			exit_error $?

###########ODIN PARTS################
		if [ ${with_odin} -eq 1 ]; then
			cd $BUILD_TEMP
			#pack the image
			tar -H ustar -c boot.img recovery.img system.img.ext4 -f ${arc_name}.tar
			#calculate the md5sum
			md5sum -t ${arc_name}.tar >> ${arc_name}.tar
			mv -f ${arc_name}.tar ${arc_name}.tar.md5
			logb "Compressing ODIN-flashable image..."
			#compress the image
			7z a ${arc_name}.tar.md5.7z ${arc_name}.tar.md5

			# exit if there was an error
			exit_error $?

			logb "Copying ODIN-flashable compressed image..."
			#copy it to the output dir
			rsync -v -P  ${arc_name}.tar.md5.7z ${out_dir}/builds/odin/

			# exit if there was an error
			exit_error $?
		fi
########END ODIN PARTS##############

	fi

	logb "Generating changes..."

	#get the date of the most recent build
	dates=($(ls ${BUILD_WWW_MOUNT_POINT}/builds/full/${distro}-${ver}-*-${device_name}.zip 2>/dev/null | cut -d '-' -f 3 | sort -r))

	# use a preset time if we couldn't get the archive times.
	if [ -z $dates ]; then
		dates=20170201
	fi

	if [ "$target" == "otapackage" ]; then
		#generate the changes
		cd ${ANDROID_BUILD_TOP}/device/${vendors[0]}/${device_name}

		echo -e "DEVICE\n---------\n" > ${out_dir}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${platform_common_dir}

		echo -e "\nMSM8916-COMMON\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${common_dir}

		echo -e "\nDEVICE-COMMON\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${ANDROID_BUILD_TOP}/vendor/${vendors[0]}/${device_name}

		echo -e "\nVENDOR\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

		cd ${ANDROID_BUILD_TOP}/vendor/${vendors[1]}/binaries

		echo -e "\nVENDOR BINARIES\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

		git log --decorate=full \
			--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt
	fi

	cd ${ANDROID_BUILD_TOP}/kernel/${vendors[0]}/${kernel_name}

	echo -e "\nKERNEL\n---------\n" >> ${out_dir}/builds/full/${arc_name}.txt

	git log --decorate=full \
		--since=$(date -d ${dates[0]} +%m-%d-%Y) >> ${out_dir}/builds/full/${arc_name}.txt

}

