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

function copy_bootimage {
	if [ "$target" == "bootimage" ]; then
		boot_pkg_dir=${BUILD_TEMP}/boot_pkg
		boot_pkg_zip=${BUILD_TEMP}/boot_j${build_num}_$(date +%Y%m%d)-${device_name}.zip

		revert_dir=${BUILD_TEMP}/wifi_revert
		revert_zip=${BUILD_TEMP}/revert_wifi_fix_j${build_num}_$(date +%Y%m%d)-${device_name}.zip

		binary_target_dir=META-INF/com/google/android
		install_target_dir=install/bin

		# create the directories
		mkdir -p ${boot_pkg_dir}/${binary_target_dir}
		mkdir -p ${boot_pkg_dir}/${install_target_dir}/installbegin
		mkdir -p ${boot_pkg_dir}/${install_target_dir}/installend
		mkdir -p ${boot_pkg_dir}/${install_target_dir}/postvalidate


		# download the update binary
		logb "\t\tFetching update binary..."
		${CURL} ${url}/updater/update-binary 1>${BUILD_TEMP}/update-binary 2>/dev/null

		logb "\t\tFetching mkbootimg..."
		${CURL} ${url}/bootimg-tools/mkbootimg 1>${BUILD_TEMP}/mkbootimg 2>/dev/null

		logb "\t\tFetching unpackbootimg..."
		${CURL} ${url}/bootimg-tools/unpackbootimg 1>${BUILD_TEMP}/unpackbootimg 2>/dev/null

		if [ -e ${ANDROID_PRODUCT_OUT}/system/lib/modules/wlan.ko ]; then
			logb "\t\tCopying wifi module..."
			cp ${ANDROID_PRODUCT_OUT}/system/lib/modules/wlan.ko ${boot_pkg_dir}/wlan.ko
			cp ${BUILD_TEMP}/update-binary ${revert_dir}/${binary_target_dir}
			mkdir -p ${revert_dir}/${binary_target_dir}
			mkdir -p ${revert_dir}/${install_target_dir}/installbegin
		fi

		cp ${ANDROID_PRODUCT_OUT}/boot.img ${boot_pkg_dir}
		cp ${BUILD_TEMP}/update-binary ${boot_pkg_dir}/${binary_target_dir}
		cp ${BUILD_TEMP}/mkbootimg ${boot_pkg_dir}/${install_target_dir}
		cp ${BUILD_TEMP}/unpackbootimg ${boot_pkg_dir}/${install_target_dir}

		# Create the scripts
		create_scripts

		#archive the image
		logb "\t\tCreating flashables..."
		cd ${boot_pkg_dir} && zip ${boot_pkg_zip} `find ${boot_pkg_dir} -type f | cut -c $(($(echo ${boot_pkg_dir}|wc -c)+1))-`
		logb "\t\tCopying boot image..."
		rsync -v -P ${boot_pkg_zip} ${out_dir}/builds/boot/
		# exit if there was an error
		exit_error $?

		if [ -e ${ANDROID_PRODUCT_OUT}/system/lib/modules/wlan.ko ]; then
			logb "\t\tCreating flashables..."
			cd ${revert_dir} && zip ${revert_zip} `find ${revert_dir} -type f | cut -c $(($(echo ${revert_dir}|wc -c)+1))-`
			logb "\t\tCopying wifi module reversion zip..."
			rsync -v -P ${revert_zip} ${out_dir}/builds/boot/
			# exit if there was an error
			exit_error $?
		fi
	fi
}

function create_scripts {
cat <<A_SCRIPT_F > ${boot_pkg_dir}/${binary_target_dir}/updater-script
package_extract_dir("install", "/tmp/install");
set_metadata_recursive("/tmp/install", "uid", 0, "gid", 0, "dmode", 0755, "fmode", 0644);
set_metadata_recursive("/tmp/install/bin", "uid", 0, "gid", 0, "dmode", 0755, "fmode", 0755);
ui_print("Extracting files...");
package_extract_dir("blobs", "/tmp/blobs");
set_metadata_recursive("/tmp/blobs", "uid", 0, "gid", 0, "dmode", 0755, "fmode", 0644);
run_program("/tmp/install/bin/run_scripts.sh", "installbegin");
run_program("/tmp/install/bin/run_scripts.sh", "installend");
run_program("/tmp/install/bin/run_scripts.sh", "postvalidate");
A_SCRIPT_F

cat <<RUN_SCRIPTS_F > ${boot_pkg_dir}/${install_target_dir}/run_scripts.sh
#!/sbin/sh

# Source the functions 
. /tmp/install/bin/functions.sh

# only run if an argument was passed
if ! [ -z \$1 ]; then
	SCRIPT_DIR=/tmp/install/bin/\${1}

	if [ -d \$SCRIPT_DIR ]; then
		# run all the scripts
		for script in \`find \${SCRIPT_DIR} -type f\` ; do
			. \$script
		done
	fi
fi

exit 0
RUN_SCRIPTS_F

cat <<SWAP_K_F > ${boot_pkg_dir}/${install_target_dir}/installbegin/swap_kernel.sh
#!/sbin/sh

#convert cpio recovery image to bootfs one

error_msg="Error creating boot image! Aborting..."

BOOT_PARTITION=/dev/block/bootdevice/by-name/boot
BOOT_IMG=/tmp/blobs/boot.img

BIN_PATH=/tmp/install/bin/

BOOT_PARTITION_BASENAME=\$(basename \$BOOT_PARTITION)
BOOT_IMG_BASENAME=\$(basename \$BOOT_IMG)

BOOT_PARTITION_TMPDIR=\$(mktemp -d)
BOOT_IMG_TMPDIR=\$(mktemp -d)

ui_print "Unpacking \$BOOT_PARTITION..."
\$BIN_PATH/unpackbootimg -i \$BOOT_PARTITION -o \$BOOT_PARTITION_TMPDIR/

if [ \$? != 0 ]; then
    ui_print \$error_msg
    exit 1
fi

ui_print "Unpacking \$BOOT_IMG..."
\$BIN_PATH/unpackbootimg -i \$BOOT_IMG -o \$BOOT_IMG_TMPDIR/

if [ \$? != 0 ]; then
    ui_print \$error_msg
    exit 1
fi

ui_print "Replacing kernel..."
rm \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage
cp \$BOOT_IMG_TMPDIR/\${BOOT_IMG_BASENAME}-zImage \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage

ui_print "Replacing dt..."
rm \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt
cp \$BOOT_IMG_TMPDIR/\${BOOT_IMG_BASENAME}-dt \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt

if [ \$? != 0 ]; then
    ui_print \$error_msg
    exit 1
fi

base=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-base\`
ramdisk_offset=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-offset\`
pagesize=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-pagesize\`
cmdline="\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-cmdline\`"
zImage=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage
ramdisk=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-ramdisk.gz
dt=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt
file_out=\$BOOT_PARTITION_TMPDIR/boot.img

ui_print "Repacking boot image..."
\$BIN_PATH/mkbootimg --kernel \$zImage --ramdisk \$ramdisk --cmdline "\$cmdline" \\
	--base \$base --pagesize \$pagesize --ramdisk_offset \$ramdisk_offset \\
	--dt \$dt -o \$file_out

if [ \$? != 0 ]; then
    ui_print \$error_msg
    exit 1
fi

ui_print "Flashing boot image..."
dd if=\$file_out of=\$BOOT_PARTITION

if [ \$? != 0 ]; then
    ui_print \$error_msg
    exit 1
fi

ui_print "Cleaning up..."
rm -r \$BOOT_PARTITION_TMPDIR
rm -r \$BOOT_IMG_TMPDIR

ui_print "Successfully flashed new boot image."
SWAP_K_F

cat <<FUNCTIONS_F > ${boot_pkg_dir}/${install_target_dir}/functions.sh
#!/sbin/sh

# Based on Chainfire's work.

# get file descriptor for output
OUTFD=\$(ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3);

# try looking for a differently named updater binary
if [ -z \$OUTFD ]; then
  OUTFD=\$(ps | grep -v "grep" | grep -o -E "updater(.*)" | cut -d " " -f 3);
fi

# same as progress command in updater-script, for example:
#
# progress 0.25 10
#
# will update the next 25% of the progress bar over a period of 10 seconds
progress() {
  if [ \$OUTFD != "" ]; then
    echo "progress \${1} \${2} " 1>&\$OUTFD;
  fi;
}

# same as set_progress command in updater-script, for example:
#
# set_progress 0.25
#
# sets progress bar to 25%
set_progress() {
  if [ \$OUTFD != "" ]; then
    echo "set_progress \${1} " 1>&\$OUTFD;
  fi;
}

# same as ui_print command in updater_script, for example:
#
# ui_print "hello world!"
#
# will output "hello world!" to recovery, while
#
# ui_print
#
# outputs an empty line
ui_print() {
  if [ \$OUTFD != "" ]; then
    echo "ui_print \${1} " 1>&\$OUTFD;
    echo "ui_print " 1>&\$OUTFD;
  else
    echo "\${1}";
  fi;
}

# Mounts the dir passed as argument 1, for example:
#
# "mount_fs /system" or "mount_fs system"
#
# will both mount the system partition on /system
#
mount_fs() {
  if [ -n \${1} ]; then
    FS_DIR=\$(echo \$1 | sed s'/\///'g)
    FS_TYPE=\$(mount | grep "on /\${FS_DIR}" | cut -d ' ' -f 5)

    if [ -z \${FS_TYPE} ]; then
        ui_print "Mounting /\${FS_DIR}..."
        mount /\${FS_DIR}
    fi
  fi
}

# Unmounts the dir passed as argument 1, for example:
#
# "umount_fs /system" or "umount_fs system"
#
# will both unmount the system partition on /system
#
umount_fs() {
  if [ -n \${1} ]; then
    FS_DIR=\$(echo \$1 | sed s'/\///'g)
    FS_TYPE=\$(mount | grep "on /\${FS_DIR}" | cut -d ' ' -f 5)

    if ! [ -z \${FS_TYPE} ]; then
        ui_print "Unmounting /\${FS_DIR}..."
        umount /\${FS_DIR}
    fi
  fi
}
FUNCTIONS_F

cat <<A_INSTALL_F > ${boot_pkg_dir}/${install_target_dir}/installend/update_wifi_module.sh
#!/sbin/sh
if [ -e /tmp/blobs/wlan.ko ]; then
	mount_fs system

	if [ -e /system/lib/modules/wlan.ko ]; then
		ui_print "Backing up previous wlan module..."
		mv /system/lib/modules/wlan.ko /system/lib/modules/wlan.ko.old
	fi
	ui_print "Copying new wlan module..."
	cp /tmp/blobs/wlan.ko /system/lib/modules/wlan.ko
	chmod 0644 /system/lib/modules/wlan.ko

	umount_fs system
fi
A_INSTALL_F

cat <<B_INSTALL_F > ${revert_dir}/${install_target_dir}/installbegin/revert_wifi_module.sh
#!/sbin/sh
mount_fs system
if [ -e /system/lib/modules/pronto/pronto_wlan.ko.old ]; then
	ui_print "Restoring previous pronto wlan module..."
	rm /system/lib/modules/pronto/pronto_wlan.ko
	mv /system/lib/modules/pronto/pronto_wlan.ko.old /system/lib/modules/pronto/pronto_wlan.ko
fi
if [ -e /system/lib/modules/wlan.ko.old ]; then
	ui_print "Restoring previous wlan module..."
	rm /system/lib/modules/wlan.ko
	mv /system/lib/modules/wlan.ko.old /system/lib/modules/wlan.ko
fi
umount_fs system
B_INSTALL_F

cp ${boot_pkg_dir}/${install_target_dir}/run_scripts.sh ${revert_dir}/${install_target_dir}/run_scripts.sh
cp ${boot_pkg_dir}/${install_target_dir}/functions.sh ${revert_dir}/${install_target_dir}/functions.sh
cp ${boot_pkg_dir}/${binary_target_dir}/updater-script ${revert_dir}/${binary_target_dir}/updater-script
}

COPY_FUNCTIONS=("${COPY_FUNCTIONS[@]}" "copy_bootimage")
