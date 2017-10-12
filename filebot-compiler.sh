#! /usr/bin/env bash

# Name: Filebot Compiler
# Description: Compile latest commit Filebot project (by rednoah)
# Author: Ivan Alejandro Marugan (hello@ialejandro.rocks)

set -e -u

# USER WITH PRIVILEGES
if [[ ${EUID} != 0 ]]; then
	echo "[${ERR}ERROR${NC}] You need root privileges" 
	exit 1
fi

# COLOR MESSAGES
OK=$(tput setaf 2)
WARN=$(tput setaf 3)
ERR=$(tput setaf 1)
NC=$(tput sgr0)

# VARS
LOGDIR="/var/log/build_filebot"
LOGFILE="${LOGDIR}/filebot_$(date +%d_%m_%Y).log"

# PARAMS
APACHE_IVY_REPO="https://git-wip-us.apache.org/repos/asf/ant-ivy.git"
APACHE_IVY_SOURCE="${HOME}/apache-ivy"
FILEBOT_CONFIG="${HOME}/.filebot"
FILEBOT_SOURCE="${HOME}/filebot"
FILEBOT_API="https://api.github.com/repos/filebot/filebot"
FILEBOT_REPO="https://github.com/filebot/filebot.git"
SLF4J_API_VERSION="1.7.9"

# Dirs and persistence commits
create_dirs() {
	# Config dir
	if [[ ! -d "${FILEBOT_CONFIG}" ]]; then
		mkdir -p "$FILEBOT_CONFIG"
	fi

	# Commits file persistence
	if [[ ! -f "${FILEBOT_CONFIG}/commits_versions" ]]; then
		touch "${FILEBOT_CONFIG}/commits_versions"
	fi

	# Log dir
	if [[ ! -d "${LOGDIR}" ]]; then
		mkdir -p "${LOGDIR}"
	fi
}

# Packages necessary to compile
install_packages() {
	# Update repositories
	apt-get -q=2 update

	# Packages
	PACKAGES="jq curl git ant"
	for SOFT in $PACKAGES; do
		EXISTS=$(which ${soft} >/dev/null; echo $?)
		if [[ ${EXISTS} != 0 ]]; then
			echo "[${WARN}WARNING${NC}] ${SOFT} isn't installed. Installing..." 
			apt-get -qq install ${SOFT} &>/dev/null
		else
			echo "[${OK}OK${NC}] ${SOFT} installed." 
		fi
	done

	# Java packages (OpenJDK and OpenJFX)
	EXISTS=$(dpkg -l | grep openjdk-8-jdk >/dev/null; echo $?)
	if [[ ${EXISTS} != 0 ]]; then
		echo "[${WARN}WARNING${NC}] OpenJDK and OpenJFX aren't installed. Installing..." 
		apt-get -qq install openjdk-8-jdk openjfx &>/dev/null
	else
		echo "[${OK}OK${NC}] OpenJDK and OpenJFX installed." 
	fi

	# Apache Ivy
	EXISTS=$(ls /usr/share/ant/lib/ivy.jar &>/dev/null; echo $?)
	if [[ ${EXISTS} != 0 ]]; then

		# Download last Apache Ivy
		if [[ -d "${APACHE_IVY_SOURCE}" ]]; then
			echo "[${WARN}WARNING${NC}] Apache Ivy directory will remove, re-download and compile." 
			rm -r "${APACHE_IVY_SOURCE}"
		fi

		# Apache Ivy compile	
		echo "[${OK}OK${NC}] Compiling Apache Ivy..."
		git clone -q ${APACHE_IVY_REPO} ${APACHE_IVY_SOURCE} 
		ant -S jar -buildfile "${APACHE_IVY_SOURCE}"
		cp "${APACHE_IVY_SOURCE}/build/artifact/jars/ivy.jar" "/usr/share/ant/lib/"

	else
		echo "[${OK}OK${NC}] Apache Ivy installed." 
	fi
}

# Download filebot repository
download() {
	echo "[${OK}OK${NC}] Download Filebot repository..." 
	git clone -q ${FILEBOT_REPO} ${FILEBOT_SOURCE}
	
	# Check download
	if [[ ! -d ${FILEBOT_SOURCE} ]]; then
		echo "[${ERR}ERROR${NC}] Download Filebot repository failed!." 
		exit 1
	fi
}

# Install dependencies (ivy.xml and slfj4)
install_dependencies() {
	echo "[${OK}OK${NC}] Downloads Filebot project dependencies..."  
	# Download dependencies ivy.xml
	ant -S -logfile ${LOGDIR}/apache_ant_$(date +%d_%m_%Y).log resolve -buildfile "${FILEBOT_SOURCE}" &>/dev/null

	# Download slf4j-api and move
	if [[ ! -f "${FILEBOT_SOURCE}/dist/lib/slf4j-api.jar" ]]; then
		wget -qO /tmp/slf4j-api.jar http://central.maven.org/maven2/org/slf4j/slf4j-api/${SLF4J_API_VERSION}/slf4j-api-${SLF4J_API_VERSION}.jar
		mkdir -p "${FILEBOT_SOURCE}/dist/lib/" "${FILEBOT_SOURCE}/lib/ivy/source/" "${FILEBOT_SOURCE}/lib/ivy/jar/" "${FILEBOT_SOURCE}/lib/ivy/javadoc/"
		cp /tmp/slf4j-api.jar "${FILEBOT_SOURCE}/dist/lib/"
		cp /tmp/slf4j-api.jar "${FILEBOT_SOURCE}/lib/ivy/source/"
		cp /tmp/slf4j-api.jar "${FILEBOT_SOURCE}/lib/ivy/jar/"
		cp /tmp/slf4j-api.jar "${FILEBOT_SOURCE}/lib/ivy/javadoc/"
		rm -rf /tmp/slf4j-api.jar
	fi
}

# Compile Filebot
compile() {
	COMMIT=$(echo ${1:0:7})
	echo "[${OK}OK${NC}] Compile Filebot (${COMMIT}) starts..." 

	# Compile starts
	ant -S -logfile ${LOGDIR}/apache_ant_$(date +%d_%m_%Y).log -buildfile "${FILEBOT_SOURCE}" &>/dev/null

	# Check compile
	if [[ -d ${HOME}/filebot ]]; then
	        cp ${FILEBOT_SOURCE}/dist/*.jar "${FILEBOT_SOURCE}/dist/Filebot.jar"
		VERSION=$(java -jar "${FILEBOT_SOURCE}/dist/Filebot.jar" -version | awk '{ print $2 }')
		mv "${FILEBOT_SOURCE}/dist/Filebot.jar" "${HOME}/Filebot_${VERSION}_(${COMMIT}).jar"

		# Success
		remove_dirs
		summary "${HOME}/Filebot_${VERSION}_(${COMMIT}).jar" "${VERSION}" "${COMMIT}"
	else
		# Fail
		summary 1
	fi
}

# Summary
summary() {
	echo ""
	if [[ -f "${1}" ]]; then
		echo "- Compile: ${OK}Success!${NC}"
		echo "- Version: Filebot ${2} (${3})"
		echo "- File path: ${1}"
	elif [[ ${1} != 0 ]]; then
		echo "- Compile: ${ERR}Failed!${NC}. Please check logs (${LOGDIR})."
		exit 1
	fi
}

# Remove dirs
remove_dirs() {
	echo "[${WARN}WARNING${NC}] Remove dir ${FILEBOT_SOURCE}..." 
	rm -rf "${FILEBOT_SOURCE}"
	echo "[${WARN}WARNING${NC}] Remove dir ${APACHE_IVY_SOURCE}..." 
	rm -rf "${APACHE_IVY_SOURCE}"
}

###################### MAIN

install_packages
create_dirs

# Compile if last commit is different
FILEBOT_LAST_COMMIT=$(curl -s -H 'Accept: application/vnd.github.v3+json' ${FILEBOT_API}/commits | jq -r .[0].sha)
EXISTS=$(cat "${FILEBOT_CONFIG}/commits_versions" | grep ${FILEBOT_LAST_COMMIT} &>/dev/null; echo $?)
if [[ $EXISTS != 0 ]]; then
	download
	install_dependencies
	compile ${FILEBOT_LAST_COMMIT}

	# Save commit version
	echo "${FILEBOT_LAST_COMMIT}" > "$FILEBOT_CONFIG/commits_versions"
else
	echo "[${WARN}WARNING${NC}] This version exists."
fi
