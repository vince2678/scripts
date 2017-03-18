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

# declare globals for argv helper
CC="gcc"
CMD_HELPER=$(mktemp)
CMD_HELPER_SRC="${CMD_HELPER}.c"

# declare some globals
build_top=
release_type=""
ver=""
distroTxt=""
recovery_variant=""
platform_common_dir=""
common_dir=""
recovery_flavour=""

kernel_name="msm8916"
vendors[0]="samsung"
vendors[1]="qcom"

lock_name=".lock"
lock=
# create a temprary working dir
tdir=$(mktemp -d)

function check_if_build_running {

	lock="${build_top}/${lock_name}"

	exec 200>${lock}

	echo -e ${RED} "Attempting to acquire lock..." ${BLUE}

	# loop if we can't get the lock
	while true; do
		flock -n 200
		if [ $? -eq 0 ]; then
			break
		else
			printf "%c" "."
			sleep 10
		fi
	done

	# set the pid
	pid=$$
	echo ${pid} 1>&200

	echo -e ${RED} "Lock acquired. PID is ${pid}" ${NC}
}

function bootstrap {

	# make the target
	${CC} --std=c99 ${CMD_HELPER_SRC} -o ${CMD_HELPER} 2>/dev/null

	# exit if we couldn't compile the code
	if [ $? != "0" ]; then
		rm -rf ${CMD_HELPER} ${CMD_HELPER_SRC} ${tdir}
		exit 1
	fi

	# loop variables
	arg_count=${#BASH_ARGV[@]}
	arg_string=""
	index=0
	# arguments are reversed, so let's flip them around
	while [ "$index" -lt "$arg_count" ]; do
		arg_string="${BASH_ARGV[$index]} ${arg_string}"
		((index=index+1))
	done

	# run the getopt helper
	CMD_OUT=`$CMD_HELPER ${arg_string}`

	# exit if we didn't read any commands.
	if [ $? != "0" ]; then
		rm -rf ${CMD_HELPER} ${CMD_HELPER_SRC} ${tdir}
		exit 1
	fi

	#source and remove the source and binary file
	. $CMD_OUT
	rm ${CMD_HELPER} ${CMD_HELPER_SRC} ${CMD_OUT}

	build_top=`realpath $android_top`

	# set the common dir
	platform_common_dir="$build_top/device/${vendors[0]}/msm8916-common/"
	if [ "$device_name" == "gtesqltespr" ] || [ "$device_name" == "gtelwifiue" ]; then
		common_dir="$build_top/device/${vendors[0]}/gte-common/"
	else
		common_dir="$build_top/device/${vendors[0]}/gprimelte-common/"
	fi

	#setup the path
	if [ -n ${BUILD_BIN_ROOT} ]; then
		export PATH=$PATH:${BUILD_BIN_ROOT}
	fi
}

function apply_patch {
	if ! [ -e ${build_top}/.patched ]; then
		echo -e ${BLUE} "Patching build top..." ${RED}
		cd ${build_top}
		count=0
		for diff_file in $(find ${common_dir}/patch/ -type f 2>/dev/null); do
			cat  ${diff_file} | patch -p1
			count=$(($count+1))
			exit_error $?
		done
		if [ ${count} -eq 0 ]; then
			echo -e ${BLUE} "Nothing to patch." ${NC}
		else
			touch ${build_top}/.patched
			echo -e ${BLUE} "Done." ${NC}
		fi
		echo -e ${BLUE} "Replacing ld.gold ..." ${RED}
		for ld_bin in $(ls prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.1*/x86_64-linux/bin/ld); do
			cp ${ld_bin} ${ld_bin}.old
			cp $(which ld.gold) $ld_bin
		done
		echo -e ${BLUE} "Done." ${NC}
		cd $OLDPWD
	fi
}

function reverse_patch {
	if [ -e ${build_top}/.patched ]; then
		echo -e ${BLUE} "Unpatching build top..." ${RED}
		cd ${build_top}
		count=0
		for diff_file in $(find ${common_dir}/patch/ -type f); do
			cat  ${diff_file} | patch -Rp1
			count=$(($count+1))
			exit_error $?
		done
		if [ ${count} -eq 0 ]; then
			echo -e ${BLUE} "Nothing to patch." ${NC}
		else
			rm ${build_top}/.patched
			echo -e ${BLUE} "Done." ${NC}
		fi
		echo -e ${BLUE} "Replacing ld.gold ..." ${RED}
		for ld_bin in $(ls prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.1*/x86_64-linux/bin/ld); do
			cp ${ld_bin}.old ${ld_bin}
			rm ${ld_bin}.old -f
		done
		echo -e ${BLUE} "Done." ${NC}
		cd $OLDPWD
	fi
}

function sync_script {
	echo -e ${BLUE} "Updating build script..." ${RED}
	url="https://raw.githubusercontent.com/Galaxy-MSM8916/build_script/master/run_build.sh"
	curl ${url} | tee $0 > /dev/null
	echo -e ${BLUE} "Done." ${NC}
}


function main {
	#move into the build dir
	cd $build_top
	#get the platform version
	platorm_version=$(grep 'PLATFORM_VERSION :' build/core/version_defaults.mk  | cut -d '=' -f 2)
	export WITH_SU
	if [ $platorm_version == "7.1.1" ]; then
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
			echo -e ${RED} "Error: Unrecognised distro" ${NC}
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
			echo -e ${RED} "Error: Unrecognised distro" ${NC}
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
			echo -e ${RED} "Error: Unrecognised distro" ${NC}
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
			echo -e ${RED} "Error: Unrecognised distro" ${NC}
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
	mkdir ${tdir}/ -p
	mkdir ${out_dir}/builds/boot -p
	mkdir ${out_dir}/builds/boot/${device_name} -p
	mkdir ${out_dir}/builds/full -p
	mkdir ${out_dir}/builds/odin -p
	mkdir ${out_dir}/builds/recovery -p
	mkdir ${out_dir}/builds/recovery/${device_name} -p
	mkdir ${out_dir}/builds/su -p
}

function exit_error {
	if [ $1 != 0 ]; then
		echo -e ${RED} "Error, aborting..." ${NC}
		if [ $silent -eq 0 ]; then
			dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`
			textStr="${dateStr}[${target}] ${distroTxt} ${ver} build %23${build_num} for ${device_name} device on ${USER}@${HOSTNAME} aborted."
			wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
		fi
		# remove the temp dir
		echo -e ${RED} "Removing temp dir..." ${NC}
		rm -rf $tdir
		echo -e ${RED} "Removing lock..." ${NC}
		rm ${lock}
		exit 1
	fi
}

function sync_vendor_trees {
	if [ ${sync_vendor} -eq 1 ]; then
		echo -e ${BLUE} "Syncing vendor trees..." ${NC}
		cd ${build_top}
		for vendor in ${vendors[*]}; do
			repo sync */${vendor}/* --force-sync
		done
		cd $OLDPWD
	fi
}


function sync_all_trees {
	if [ ${sync_all} -eq 1 ]; then
		echo -e ${BLUE} "Syncing all trees..." ${NC}
		cd ${build_top}
		repo sync --force-sync
		cd $OLDPWD
	fi
}

function make_targets {
	#start building
	make -j${job_num} $target CM_UPDATER_OTA_URI="cm.updater.uri=http://grandprime.ddns.net/OTA/api"
	#cowardly exit 1 if we fail.
	exit_error $?

	#build su
	if [ $ver == "13.0" ]; then
		make -j${job_num} addonsu
		#cowardly exit 1 if we fail.
		exit_error $?
	fi
}

function move_files {

	if [ "$target" == "recoveryimage" ]; then

		#copy the recovery image
		cp ${ANDROID_PRODUCT_OUT}/recovery.img $tdir
		cd $tdir
		#archive the image
		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=${recovery_flavour}-${distro}-${ver}-$(date +%Y%m%d)-${device_name}
		else
			rec_name=${recovery_flavour}-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
		fi

		echo -e ${BLUE} "Copying recovery image..." ${NC}
		tar cf ${rec_name}.tar recovery.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/recovery/${device_name}/${rec_name}.tar || exit 1

	elif [ "$target" == "bootimage" ]; then

		#copy the boot image
		cp ${ANDROID_PRODUCT_OUT}/boot.img $tdir
		cd $tdir
		#archive the image
		#define some variables
		if [ -z ${build_num} ]; then
			rec_name=bootimage-${distro}-${ver}-$(date +%Y%m%d)-${device_name}
		else
			rec_name=bootimage-${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${device_name}
		fi

		echo -e ${BLUE} "Copying boot image..." ${NC}
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

		echo -e ${BLUE} "Copying files..." ${NC}
		#move into the build dir
		#copy the images
		cp ${ANDROID_PRODUCT_OUT}/boot.img $tdir
		cp ${ANDROID_PRODUCT_OUT}/recovery.img $tdir
		cp ${ANDROID_PRODUCT_OUT}/system.img $tdir/system.img.ext4

		cd $tdir

		echo -e ${BLUE} "Copying recovery image..." ${NC}
		tar cf ${rec_name}.tar recovery.img
		rsync -v -P ${rec_name}.tar ${out_dir}/builds/recovery/${device_name}/${rec_name}.tar || exit 1

		if [ $ver == "13.0" ]; then
			echo -e ${BLUE} "Copying su image..." ${NC}
			rsync -v -P ${ANDROID_PRODUCT_OUT}/addonsu-arm.zip ${out_dir}/builds/su/addonsu-arm_j${build_num}_.zip || exit 1
		fi

		ota_out=${distro}_${device_name}-ota-${BUILD_NUMBER}.zip
		#check if our correct binary exists
		echo -e ${BLUE} "Locating update binary..." ${NC}
		if [ -e ${build_top}/META-INF ]; then
			ota_bin="META-INF/com/google/android/update-binary"

			echo -e ${BLUE} "Found update binary..." ${NC}
			cp -dpR ${build_top}/META-INF $tdir/META-INF
			cp -ndpR ${build_top}/META-INF ./
			#delete the old binary
			echo -e ${BLUE} "Patching zip file unconditionally..." ${NC}
			zip -d ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
			zip -ur ${ANDROID_PRODUCT_OUT}/${ota_out} ${ota_bin}
		fi

		#copy the zip in the background
		echo -e ${BLUE} "Copying zip image..." ${NC}

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
			cd $tdir
			#pack the image
			tar -H ustar -c boot.img recovery.img system.img.ext4 -f ${arc_name}.tar
			#calculate the md5sum
			md5sum -t ${arc_name}.tar >> ${arc_name}.tar
			mv ${arc_name}.tar ${arc_name}.tar.md5
			echo -e ${BLUE} "Compressing ODIN-flashable image..." ${NC}
			#compress the image
			7z a ${arc_name}.tar.md5.7z ${arc_name}.tar.md5

			# exit if there was an error
			exit_error $?

			echo -e ${BLUE} "Copying ODIN-flashable compressed image..." ${NC}
			#copy it to the output dir
			rsync -v -P  ${arc_name}.tar.md5.7z ${out_dir}/builds/odin/

			# exit if there was an error
			exit_error $?
		fi
########END ODIN PARTS##############

	fi

	echo -e ${BLUE} "Generating changes..." ${NC}

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

function clean_target {
	#start cleaning up
	echo -e ${BLUE} "Removing temp dir..." ${NC}
	rm -r $tdir
	echo -e ${BLUE} "Cleaning build dir..." ${NC}
	cd ${ANDROID_BUILD_TOP}/
	echo -e ${BLUE} "Removing lock..." ${NC}
	rm ${lock}

	if [ ${clean_target_out} -eq 1 ]; then
		if [ "$target" == "otapackage" ]; then
			make clean
		fi
	fi
}

function print_start_build {
	if [ ${build_num} -ge 1 ]; then
		echo -e ${BLUE} "\n==================================================" ${NC}
		echo -e ${BLUE} "Build started on Jenkins.\n" ${NC}
		echo -e ${BLUE} "BUILDING #${build_num} FROM ${USER}@${HOSTNAME}\n" ${NC}
		echo -e ${BLUE} "Release type: ${release_type} \n" ${NC}
		arc_name=${distro}-${ver}_j${build_num}_$(date +%Y%m%d)_${release_type}-${device_name}
		echo -e ${BLUE} "Archive prefix is: ${arc_name} \n" ${NC}
		echo -e ${BLUE} "Output Directory: ${out_dir}\n" ${NC}
		echo -e ${BLUE} "===================================================\n" ${NC}

		if [ $silent -eq 0 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`
		textStr="${dateStr}[${target}] ${distroTxt} ${ver} build %23${build_num} started for device ${device_name} via Jenkins, running on ${USER}@${HOSTNAME}."

		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	   fi
	fi
}

function print_end_build {
	echo -e ${BLUE} "Done." ${NC}
	if [ $silent -eq 0 ]; then
		dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`
		textStr="${dateStr}[${target}] ${distroTxt} ${ver} build %23${build_num} for ${device_name} device on ${USER}@${HOSTNAME} completed successfully."
		wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
	fi
}

function extract_code {
# save the source code to a temp file
cat <<SRC > ${CMD_HELPER_SRC}
#define _XOPEN_SOURCE 600
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <errno.h>
#include <getopt.h>

#define SCRIPT_TEMPLATE "RB_"
// global variables for keeping parsed cmd line arguments.
int silent=0;
int job=0;
int build=0;
int with_su=0;
int sync_vendor=0;
int sync_all=0;
int odin=0;
int clean_flag=0;
char target[256];
char type[256];
char distro[256];
char device_name[256];
char output_dir[256];
char android_top[256];
int eflag = 0;

/* Helper function that parses command line arguments to main
 */
void parse_commmand_line(int argc, char *argv[]) {

    //variable to store return status of getopt().
    int opt;
    int optind = 0;
    int tflag = 0;
    int nflag = 0;
    int pflag = 0;
    int oflag = 0;
    int dflag = 0;

	static struct option long_options[] = {
		/* *name ,  has_arg,           *flag,  val */
		{"silent",	no_argument,       0, 's' },
		{"sync",	no_argument,       0, 'v' },
		{"sync_all",	no_argument,       0, 'a' },
		{"su",	no_argument,       0, 'u' },
		{"odin",	no_argument,       0, 'c' },
		{"clean",	no_argument, 0,  'r' },
		{"target",	required_argument, 0,  't' },
		{"device",	required_argument, 0,  'n' },
		{"path",	required_argument, 0, 'p'  },
		{"output",	required_argument, 0, 'o'  },
		{"distro",	required_argument, 0,  'd' },
		{"type",	required_argument, 0,  'e' },
		{0,         0,                 0,  0 }
	};

    while ( (opt = getopt_long (argc, argv, "t:n:j:p:o:b:d:e:scravu", long_options, &optind)) != -1 ) {
        switch (opt){
            case 'u': //sync
		with_su=1;
		break;
            case 'a': //sync
		sync_all=1;
		break;
            case 'v': //sync
		sync_vendor=1;
		break;
            case 'r': //clean
		clean_flag=1;
		break;
	    case 's': //silent
		silent=1;
                break;
            case 'e': //build type
		strcpy(type, optarg);
		eflag = 1;
                break;
	    case 'c': //odin
		odin=1;
                break;
            case 't': // target
		strcpy(target, optarg);
		tflag = 1;
                break;
            case 'n': // device
		strcpy(device_name, optarg);
		nflag = 1;
                break;
            case 'j': //job
            //get the number provided with the argument.
                job = atoi (optarg);
                break;
            case 'p': //path
		strcpy(android_top, optarg);
		pflag = 1;
                break;
            case 'o': // output
		strcpy(output_dir, optarg);
		oflag = 1;
                break;
            case 'b': //make this optional
            //get the number provided with the argument.
                build = atoi (optarg);
                break;
            case 'd': //distro
		strcpy(distro, optarg);
		dflag = 1;
                break;
            case '?': // case in which the argument is not recognised.
            //No break statement == the case 'falls thru' to the next one.
            default: // if an invalid argument is found.
                fprintf (stderr, "Usage: %s [OPTION]\n",argv[0]);
                fprintf (stderr, "  -d, --distro\tdistribution name\n" );
                fprintf (stderr, "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" );
                fprintf (stderr, "  -e, --type\twhere type is one of user|userdebug|eng\n" );
                fprintf (stderr, "  -n, --device\tdevice name\n" );
                fprintf (stderr, "  -p, --path\tbuild top path\n" );
                fprintf (stderr, "  -o, --output\toutput path (path to jenkins archive dir)\n");
                fprintf (stderr, "\nOptional commands:\n");
                fprintf (stderr, "  -b\tbuild number\n");
                fprintf (stderr, "  -s, --silent\tdon't publish to Telegram\n");
                fprintf (stderr, "  -c, --odin\tbuild compressed (ODIN) images\n");
                fprintf (stderr, "  -r, --clean\tclean build directory on completion\n");
                fprintf (stderr, "  -a, --sync_all\tSync entire build tree\n");
                fprintf (stderr, "  -v, --sync\tSync device/kernel/vendor trees\n");
                fprintf (stderr, "  -u, --su\tAdd SU to build\n");
                fprintf (stderr, "  -j\tnumber of parallel make jobs to run\n");
                exit (EXIT_FAILURE);
        }
    }

    if ( (argc < 6) && !(sync_all || sync_vendor)) {
                fprintf (stderr, "Usage: %s [OPTION]\n",argv[0]);
                fprintf (stderr, "  -d, --distro\tdistribution name\n" );
                fprintf (stderr, "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" );
                fprintf (stderr, "  -e, --type\twhere type is one of user|userdebug|eng\n" );
                fprintf (stderr, "  -n, --device\tdevice name\n" );
                fprintf (stderr, "  -p, --path\tbuild top path\n" );
                fprintf (stderr, "  -o, --output\toutput path (path to jenkins archive dir)\n");
                fprintf (stderr, "\nOptional commands:\n");
                fprintf (stderr, "  -b\tbuild number\n");
                fprintf (stderr, "  -s, --silent\tdon't publish to Telegram\n");
                fprintf (stderr, "  -c, --odin\tbuild compressed (ODIN) images\n");
                fprintf (stderr, "  -r, --clean\tclean build directory on completion\n");
                fprintf (stderr, "  -a, --sync_all\tSync entire build tree\n");
                fprintf (stderr, "  -u, --su\tAdd SU to build\n");
                fprintf (stderr, "  -v, --sync\tSync device/kernel/vendor trees\n");
                fprintf (stderr, "  -j\tnumber of parallel make jobs to run\n");
        exit (EXIT_FAILURE);
    }

    if ( (sync_all == 0) && (sync_vendor == 0) ) {
	    if ( dflag == 0 ) {
		fprintf (stderr, "%s: Missing -d (distro) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( tflag == 0 ) {
		fprintf (stderr, "%s: Missing -t (target) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( nflag == 0 ) {
		fprintf (stderr, "%s: Missing -n (device name) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( oflag == 0 ) {
		fprintf (stderr, "%s: Missing -o (output path) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
    }
    if ( pflag == 0 ) {
        fprintf (stderr, "%s: Missing -p (build path) option. \n", argv[0]);
        exit (EXIT_FAILURE);
    }
}

void write_src_file() {

	// get a temp name
	char * temp_name = tempnam( "/tmp", SCRIPT_TEMPLATE);

	FILE * temp_file;

	// if we can't get a random name, just use a fixed one.
	if ( temp_name == NULL ) {
		temp_name = "/tmp/RB_src";
	}

	// exit if we can't open the file
	if ( ( temp_file = fopen(temp_name, "w" ) ) == NULL ) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}

	// start writing the env variables to the file
	fprintf ( temp_file, "#!/bin/bash\n");
	fprintf ( temp_file, "silent=%d\n", silent );
	fprintf ( temp_file, "build_num=%d\n", build );
	fprintf ( temp_file, "clean_target_out=%d\n", clean_flag );

	// set the su property
	if (with_su) fprintf ( temp_file, "WITH_SU=true\n");
		else fprintf ( temp_file, "WITH_SU=false\n");

	// set the job number
	if (job) fprintf ( temp_file, "job_num=%d\n", job );

	// set the build type
	if (eflag) fprintf ( temp_file, "build_type=%s\n", type );
		else  fprintf ( temp_file, "build_type=userdebug\n");

	fprintf ( temp_file, "with_odin=%d\n", odin );
	fprintf ( temp_file, "sync_all=%d\n", sync_all );
	fprintf ( temp_file, "sync_vendor=%d\n", sync_vendor );
	fprintf ( temp_file, "target=%s\n", target );
	fprintf ( temp_file, "distro=%s\n", distro );
	fprintf ( temp_file, "device_name=%s\n", device_name );
	fprintf ( temp_file, "out_dir=%s\n", output_dir );
	fprintf ( temp_file, "android_top=%s\n", android_top );

	// close the file
	fclose(temp_file);

	// print the temp name
	printf("%s\n", temp_name);

	// free the name
	free(temp_name);

}

/* Main function
 */
int main(int argc, char *argv[]){

	//parse the command line arguments.
	parse_commmand_line ( argc, argv );
	// write the source file
	write_src_file ();
    return 0;
}
SRC
}

# save the code
extract_code
# setup env vars
bootstrap "$@"
# check if any other builds are running
check_if_build_running
# reverse any previously applied patch
reverse_patch
# sync the repos
sync_vendor_trees
sync_all_trees
# apply the patch
apply_patch
if [ "${distro}" != "" ]; then
	# run the main function
	main "$@"
	# print the build start text
	print_start_build
	# make the targets
	make_targets
	# copy the files
	move_files
	# copy the target
	clean_target
	# end the build
	print_end_build
	# reverse any previously applied patch
	reverse_patch
fi
# sync the build script
sync_script "$@"
