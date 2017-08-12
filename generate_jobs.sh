#!/bin/bash

SEPARATOR="!"
COUNT=1

NEWLINE="
"

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -i | --input Path to job description file"
    echo
    echo "  -d | --path  Path to Jenkins' job directory"
    echo "  -h | --help  Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
	print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -i | --input)           shift
                                JOBS_FILE=$1
                                ;;
        -d | --path )           shift
                                JENKINS_JOB_DIR=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

if [ "x$JENKINS_JOB_DIR" == "x" ]; then
	JENKINS_JOB_DIR="/var/lib/jenkins/jobs"
fi

LINES=$(cat ${JOBS_FILE} | sed s"/ /${SEPARATOR}/"g | grep -v "#")

function get_var {
	eval $2="$(echo $1 | cut -d "${SEPARATOR}" -f $COUNT | sed s'/__/ /'g)"
	COUNT=$((COUNT+1))
}

function generate_folder_config() {
# generate_folder_config FOLDER_NAME CONFIG_PATH
local FOLDER_NAME=$(echo $1 | sed s'/_/ /'g)
local CONFIG_PATH=$2

if ! [ -f $CONFIG_PATH ]; then
mkdir -p $(dirname $CONFIG_PATH)
cat <<CONFIG_FILE_F > ${CONFIG_PATH}
<?xml version='1.0' encoding='UTF-8'?>
<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.0.4">
  <actions/>
  <description></description>
  <displayName>$FOLDER_NAME</displayName>
  <properties>
    <com.cloudbees.hudson.plugins.folder.properties.FolderCredentialsProvider_-FolderCredentialsProperty>
      <domainCredentialsMap class="hudson.util.CopyOnWriteMap\$Hash">
        <entry>
          <com.cloudbees.plugins.credentials.domains.Domain plugin="credentials@2.1.13">
            <specifications/>
          </com.cloudbees.plugins.credentials.domains.Domain>
          <java.util.concurrent.CopyOnWriteArrayList>
            <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.1.13">
              <id>fc700093-f1c0-4a9f-9fe4-05ffbf031a04</id>
              <description></description>
              <password>{AQAAABAAAAEwTMI9ZHoBapZN8l7SW6evceOEy31UC5u88XLukcQDpGpw1eMBUBzIrWsz9fJaGIGyDo2mVJ78LydXkI9ol2hUWO7uS1bWV7LMK+Zg+k4E6FljJQ1ehKJ+igbJ0BnKcIIXMJ66YwjI/YPiwgAoIiT0P0A/J8RKEM5lrIH/bbIQVMf0VLtkLmRU7c5SLPgSCBM+lcTt+AV36ma9RPs3NMCMhxQu/PhUkgfDt3TR7sbsB96b4j3493qnPTxlhyqO967VajslELFUBVTrnDaXHJomQ++iyYGxQYGHx2fRn3H2hNDBjJQpybRScIisVg7KZ3f9okjnibNIgieC6RzA6Vo5Q25K9eZEOTkdP4pRynnB0skkwDhcYMAQ3Qv2dYrv7UASbgtlSJSoNbzHB/dEvi/kQk1fXAcz5+O8ip152tvIobk=}</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
            <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl plugin="credentials@2.1.13">
              <id>86eb4de2-2fe4-414d-9b01-4c06bc24fc1e</id>
              <description></description>
              <password>{AQAAABAAAAEwaNWmwgx5aqY+gvly4TKICpz9nMqSX0CbXkoqeSJFdnT79NBCjhvqHdR0gniSHHlSQ79zESSCloOB8/4uMaRQHnZX3Qtdz0B/W1wKrw2uuVhKL492vHScNTGVahKTYIqlOptMmHbReBeHKYh70hdm57FRi5u0tDCaX/VKGVk6pZzSKoCDsYpY1gYbqGcUPP6teiZm6elyFbLu2nFzz+Dtnk764yOheT7FYLgNBQA9Ll1LBpZBKWI6dVx7Po8kFLfd5d78xkdW9zSohQqn/CvfOt9ZwJ04nxTzZweMFzx3HxQMEa51TQN6yLV7a/c6JSa0rDi0w9Rey60fgx9i+b6ejiwq0bE9aQKCfn3eDLjM3rbRnfrfM8HymRVIyZZO1r2h7h9FfsnkY0O7JBrY4TwaaJOhMFWGQwko51+dGcSPB8I=}</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
          </java.util.concurrent.CopyOnWriteArrayList>
        </entry>
      </domainCredentialsMap>
    </com.cloudbees.hudson.plugins.folder.properties.FolderCredentialsProvider_-FolderCredentialsProperty>
  </properties>
  <folderViews class="com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder">
    <views>
      <hudson.model.AllView>
        <owner class="com.cloudbees.hudson.plugins.folder.Folder" reference="../../../.."/>
        <name>all</name>
        <description></description>
        <filterExecutors>false</filterExecutors>
        <filterQueue>false</filterQueue>
        <properties class="hudson.model.View\$PropertyList"/>
      </hudson.model.AllView>
    </views>
    <primaryView>all</primaryView>
    <tabBar class="hudson.views.DefaultViewsTabBar"/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/>
</com.cloudbees.hudson.plugins.folder.Folder>
CONFIG_FILE_F
fi
}

# clean up the dirs
for jobs_folder in $(find $JENKINS_JOB_DIR  -name jobs | tac); do
	for job_dir in $(find $jobs_folder -maxdepth 1 -type d); do
		file_count=$(find $job_dir -type f | wc -l)
		if [ $file_count -le 3 ]; then
			rm -r $job_dir
		fi
	done
done

rmdir $(find $JENKINS_JOB_DIR -type d -empty)

for LINE in $LINES; do

	BLOCKING_JOBS="administrative/block_all_jobs"
	BLOCKING_JOBS+="${NEWLINE}"

	COUNT=1

	# variables to be extracted from the job line. Order matters
	VARIABLES="JOB_DIR DIST_LONG DIST DIST_SHORT BUILD_DIR_BASENAME DIST_VERSION DEVICE_CODENAME DEVICE_MODEL BUILD_TARGET BUILD_TYPE EXTRA"

	for variable in ${VARIABLES}; do
		get_var $LINE $variable
	done

	JOB_DIR_PROPER=

	while [ $(dirname $JOB_DIR) != "." ]; do
		JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"
		JOB_DIR=$(dirname $JOB_DIR)
	done
	JOB_DIR_PROPER="$(basename $JOB_DIR)/jobs/${JOB_DIR_PROPER}"

	# generate the job configs
	JOB_DIR=$JOB_DIR_PROPER
	while [ $(dirname $JOB_DIR) != "." ]; do
		JOB_DIR_NAME=$(basename $JOB_DIR)
		if [ $JOB_DIR_NAME == "jobs" ]; then
			JOB_DIR_NAME=$(dirname $JOB_DIR)
			[ $(basename $JOB_DIR_NAME) != "." ] && JOB_DIR_NAME=$(basename $JOB_DIR_NAME)

			generate_folder_config $JOB_DIR_NAME ${JENKINS_JOB_DIR}/$(dirname $JOB_DIR)/config.xml
		fi
		echo
		JOB_DIR=$(dirname $JOB_DIR)
	done

	JOB_BASE_NAME=${DIST_SHORT}-${DIST_VERSION}-${DEVICE_CODENAME}
	JOB_DIR_PATH=${JENKINS_JOB_DIR}/${JOB_DIR_PROPER}/${JOB_BASE_NAME}/
	CONFIG_PATH=${JOB_DIR_PATH}/config.xml

	mkdir -p $JOB_DIR_PATH

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
		SHELL_COMMANDS+="--output \${JENKINS_HOME}/jobs/${JOB_DIR_PROPER}\${JOB_BASE_NAME}/builds/\${BUILD_NUMBER}/archive/ \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="-b \${BUILD_NUMBER} --type=${BUILD_TYPE} -v \\"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="--host jenkins@jenkins.msm8916.com"

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
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;find \${JENKINS_HOME}/jobs/${EXTRA}/jobs/\${JOB_BASE_NAME}/lastStable/archive/builds/full -type f -execdir ln &apos;{}&apos; \${htmlroot}/builds/full/ \;&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rename s&apos;/_j[0-9]*_/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rename s&apos;/_/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rename s&apos;/--/-/&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rename s&apos;/changelog-//&apos;g \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rename s&apos;/zip\.md5/md5sum/&apos;g  \${htmlroot}/builds/full/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;find \${JENKINS_HOME}/jobs/${EXTRA}/jobs/\${JOB_BASE_NAME}/lastStable/archive/builds/odin -type f -execdir ln &apos;{}&apos; \${htmlroot}/builds/odin/ \;&quot;"

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
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rm -f \${htmlroot}/builds/recovery/${DEVICE_CODENAME}/*&quot;"
		SHELL_COMMANDS+=${NEWLINE}
		SHELL_COMMANDS+="ssh jenkins@jenkins.msm8916.com &quot;rm -f \${htmlroot}/builds/full/*${DIST_VERSION}*${DEVICE_CODENAME}.*&quot;"

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
