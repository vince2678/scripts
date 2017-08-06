#!/bin/bash

SEPARATOR="!"
COUNT=1

NEWLINE="
"

if [ "x$1" == "x" ]; then
	echo "usage: $0 /path/to/job/file.txt [/path/to/job/dir]"
	exit 1
fi

JOBS_FILE=$1

if [ "x$2" == "x" ]; then
	JENKINS_JOB_DIR="/var/lib/jenkins/jobs"
else
	JENKINS_JOB_DIR=$2
fi

LINES=$(cat ${JOBS_FILE} | sed s"/ /${SEPARATOR}/"g | grep -v "#")

function get_var {
	eval $2="$(echo $1 | cut -d "${SEPARATOR}" -f $COUNT | sed s'/__/ /'g)"
	COUNT=$((COUNT+1))
}

for LINE in $LINES; do

	BLOCKING_JOBS="administrative/block_all_jobs"
	BLOCKING_JOBS+="${NEWLINE}"

	COUNT=1

	# variables to be extracted from the job line. Order matters
	VARIABLES="JOB_DIR DIST_LONG DIST DIST_SHORT BUILD_DIR_BASENAME DIST_VERSION DEVICE_CODENAME DEVICE_MODEL BUILD_TARGET BUILD_TYPE EXTRA"

	for variable in ${VARIABLES}; do
		get_var $LINE $variable
	done

	JOB_BASE_NAME=${DIST_SHORT}-${DIST_VERSION}-${DEVICE_CODENAME}
	CONFIG_PATH=${JENKINS_JOB_DIR}/${JOB_DIR}/jobs/${JOB_BASE_NAME}/config.xml

	mkdir -p $(dirname ${CONFIG_PATH})

	if [ "$BUILD_TARGET" == "otapackage" ] || [ "$BUILD_TARGET" == "bootimage" ] || [ "$BUILD_TARGET" == "recoveryimage" ]; then

		ASSIGNED_NODE="  <assignedNode>"
		ASSIGNED_NODE+="!master"
		ASSIGNED_NODE+="</assignedNode>"

		CAN_ROAM=false

		JOB_DESCRIPTION="${DIST_LONG} ${DIST_VERSION} for the $DEVICE_MODEL"

		SHELL_COMMANDS="\${BUILD_BIN_ROOT}/run_build.sh --path \${BUILD_ANDROID_ROOT}/${BUILD_DIR_BASENAME} --distro ${DIST} \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="--device ${DEVICE_CODENAME} --target ${BUILD_TARGET} -j \${MAX_JOB_NUMBER} \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="--output \${JENKINS_HOME}/jobs/${JOB_DIR}/jobs/\${JOB_BASE_NAME}/builds/\${BUILD_NUMBER}/archive/ \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="-b \${BUILD_NUMBER} --type=${BUILD_TYPE} -v \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="--host jenkins@grandprime.ddns.net"

		if [ "$BUILD_TARGET" == "otapackage" ]; then
			SHELL_COMMANDS+=" --clean"
		fi

		if [ "$DIST_SHORT" == "oc" ]; then
			SHELL_COMMANDS+=" --oc"
		fi

		if [ "$EXTRA" != "x" ]; then
			SHELL_COMMANDS+=" $EXTRA"
		fi
	elif [ "$BUILD_TARGET" == "promote" ]; then
		
		ASSIGNED_NODE=

		BLOCKING_JOBS+="$EXTRA/${JOB_BASE_NAME}"

		CAN_ROAM=true

		JOB_DESCRIPTION="Promote Latest ${DIST_LONG} ${DIST_VER} build for ${DEVICE_MODEL}"

		DIST_LONG="Promote ${DIST_LONG}"

		if [ "$DIST_VERSION" == "13.0" ]; then
			OTA_VER=13
		elif [ "$DIST_VERSION" == "14.1" ]; then
			OTA_VER=14
		fi

		SHELL_COMMANDS="htmlroot=/var/www/html/OTA${OTA_VER}/"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;find \${JENKINS_HOME}/jobs/${EXTRA}/jobs/\${JOB_BASE_NAME}/lastStable/archive/builds/full -type f -execdir ln &apos;{}&apos; \${htmlroot}/builds/full/ \;&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rename s&apos;/_j[0-9]*_/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rename s&apos;/_/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rename s&apos;/--/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rename s&apos;/changelog-//&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rename s&apos;/zip\.md5/md5sum/&apos;g  \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;find \${JENKINS_HOME}/jobs/${EXTRA}/jobs/\${JOB_BASE_NAME}/lastStable/archive/builds/odin -type f -execdir ln &apos;{}&apos; \${htmlroot}/builds/odin/ \;&quot;"

	elif [ "$BUILD_TARGET" == "demote" ]; then

		ASSIGNED_NODE=

		CAN_ROAM=true

		JOB_DESCRIPTION="Demote ${DIST_LONG} ${DIST_VER} build for ${DEVICE_MODEL}"

		DIST_LONG="Demote ${DIST_LONG}"

		if [ "$DIST_VERSION" == "13.0" ]; then
			OTA_VER=13
		elif [ "$DIST_VERSION" == "14.1" ]; then
			OTA_VER=14
		fi

		SHELL_COMMANDS="htmlroot=/var/www/html/OTA${OTA_VER}/"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rm -f \${htmlroot}/builds/recovery/${DEVICE_CODENAME}/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@grandprime.ddns.net &quot;rm -f \${htmlroot}/builds/full/*${DIST_VERSION}*${DEVICE_CODENAME}.*&quot;"

	fi

	echo "Generating ${DIST_LONG} ${DIST_VERSION} job for $DEVICE_MODEL..."

cat <<CONFIG_FILE_F > ${CONFIG_PATH}
<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description>${JOB_DESCRIPTION}</description>
  <displayName>${DIST_LONG} ${DIST_VERSION}: ${DEVICE_CODENAME} [ ${DEVICE_MODEL} ]</displayName>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.plugins.buildblocker.BuildBlockerProperty plugin="build-blocker-plugin@1.7.3">
      <useBuildBlocker>true</useBuildBlocker>
      <blockLevel>GLOBAL</blockLevel>
      <scanQueueFor>DISABLED</scanQueueFor>
      <blockingJobs>${BLOCKING_JOBS}</blockingJobs>
    </hudson.plugins.buildblocker.BuildBlockerProperty>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>-1</daysToKeep>
        <numToKeep>4</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>4</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
  </properties>
  <scm class="hudson.scm.NullSCM"/>
${ASSIGNED_NODE}
  <canRoam>${CAN_ROAM}</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command>${SHELL_COMMANDS}</command>
    </hudson.tasks.Shell>
  </builders>
  <publishers/>
  <buildWrappers>
    <hudson.plugins.timestamper.TimestamperBuildWrapper plugin="timestamper@1.8.8"/>
    <hudson.plugins.ansicolor.AnsiColorBuildWrapper plugin="ansicolor@0.5.0">
      <colorMapName>xterm</colorMapName>
    </hudson.plugins.ansicolor.AnsiColorBuildWrapper>
  </buildWrappers>
</project>
CONFIG_FILE_F

done
