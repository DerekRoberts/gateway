#!/bin/bash
#
# Manages Docker containers, images and environments.  Usage formating borrowed
# directly from Docker.  Proceed to Main section for directions.
#
# Halt on errors or uninitialized variables
#
set -e -o nounset


################################################################################
# Functions - must preceed execution
################################################################################


# Output rejection message and exit
#
inform_exit ()
{
	# Expects one error string
	echo
	echo $1
	echo
	exit
}


# Output message and command, then execute command
#
inform_exec ()
{
	# Expects a message and command
	echo
	echo "*** ${1} *** ${2}"
	echo
	${2} || \
		{
			echo "${2} failed!"
			exit
		}
	echo
	echo
}


# Output usage instructions and quit
#
usage_error ()
{
	# Expects one usage string
	inform_exit "Usage: ./gateway.sh $1"
}


# Output usage help
#
usage_help ()
{
	echo
	echo "Usage: ./gateway.sh COMMAND [OPTIONS] [arguments]"
	echo
	echo "Commands:"
	echo "	build       Build a Docker image"
	echo "	run         Run a new Docker container"
	echo "	rm          Remove a Docker container"
	echo "	test        Run and inspect test container pdc-0000"
	echo "	save        Save the current Docker image as .tar"
	echo "	load        Load a Docker image from .tar"
	echo "	providers   Modify a Gateway's providers.txt"
	echo "	configure   Configures Docker, MongoDB and bash"
	echo "	keygen      Create id_rsa, id_rsa.pub and known_hosts"
	echo
	echo "'./gateway.sh COMMAND' provides more information as necessary."
	echo
	exit
}


# Verify a condition is met, else inform and exit
#
verify_condition ()
{
	# Expects a condition and an output message
	if ! ( ${1} )
	then
		inform_exit "ERROR: ${2}"
	fi
}


# Check Internet connectivity
#
verify_internet ()
{
	if [[ "$(ping -c 1 8.8.8.8 | grep '100% packet loss' )" != "" ]]
	then
	    inform_exit "ERROR: Build requires an Internet connection"
	fi
}


# Verify that GATEWAY_ID is an integer 1 - 999
#
verify_gateway_id ()
{
	# Expects a gateway ID#
	if ! ([[ ${1} =~ ^[0-9]+$ ]]&&[ ${1} -gt 0 ]&&[ ${1} -lt 1000 ])
	then
		inform_exit "ERROR: ${1} is not a valid Gateway ID number"
	fi

	if [[ ${1} == 0* ]]
	then
		inform_exit "ERROR: do not start Gateway ID numbers with 0"
	fi
}


# Verify the status of id_rsa, id_rsa.pub and known_hosts
#
verify_ssh_files ()
{
	# Verify id_rsa, id_rsa.pub and known_hosts are present
	verify_condition "[ -f ${PATH_SSH_KEYS}/id_rsa ]" "id_rsa missing from ${PATH_SSH_KEYS}"
	verify_condition "[ -f ${PATH_SSH_KEYS}/id_rsa.pub ]" "id_rsa.pub missing from ${PATH_SSH_KEYS}"
	verify_condition "[ -f ${PATH_SSH_KEYS}/known_hosts ]" "known_hosts missing from ${PATH_SSH_KEYS}"
}

# Verify the status of id_rsa, id_rsa.pub and known_hosts
#
create_ssh_files ()
{
	# Create ç
	sudo mkdir -p ${PATH_SSH_KEYS}

	# Create known_hosts
	sudo /bin/bash -c "ssh-keyscan -t rsa -H ${IP_HUB} | tee -a ${PATH_SSH_KEYS}/known_hosts"

	# Create id_rsa and id_rsa.pub
	sudo ssh-keygen -b 4096 -t rsa -N '' -C "$(whoami)@$(hostname)" -f ${PATH_SSH_KEYS}/id_rsa

	# Echo public key
	echo
	echo "New SSH files generated.  Please take note of the public key."
	echo
	cat ${PATH_SSH_KEYS}/id_rsa.pub
	echo
	echo
}

# Build a Docker gateway image
#
docker_build ()
{
	# W/o Internet build fails and destroys existing images
	verify_internet
	inform_exec "Building gateway" "sudo docker build -t ${DOCKER_REPO_NAME} ."
	sudo docker pull mongo
}


# Run a gateway and database containers - for deployment
#
docker_run ()
{
	# Verify ssh files are in order
	verify_ssh_files

	# Check parameters and assign variables
	[ $# -eq 1 ]||[ $# -eq 2 ]|| \
		usage_error "run [Gateway ID#] [optional: CPSID#1,CPSID#1,...,CPSID#n]"
	#
	export GATEWAY_ID=${1}
	export DOCTORS=${2:-""}
	#
	verify_gateway_id ${GATEWAY_ID}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
	export DATABASE_NAME=${GATEWAY_NAME}-db
	export GATEWAY_PORT=`expr 40000 + ${GATEWAY_ID}`

	# Run a database and gateway
	sudo docker run -d --name ${DATABASE_NAME} -h ${DATABASE_NAME} --restart='always' mongo --storageEngine wiredTiger || echo ${DATABASE_NAME} exists!
	#
	inform_exec "Running gateway" \
		"sudo docker run -d --name ${GATEWAY_NAME} -h ${GATEWAY_NAME} --link ${DATABASE_NAME}:database -e gID=${GATEWAY_ID} -p ${GATEWAY_PORT}:3001 --env-file=config.env --restart='always' ${DOCKER_ENDPOINT} ${DOCKER_REPO_NAME}"

	# If there are any CPSIDs, then pass them to the gateway
	[ ${DOCTORS} == "" ]|| \
		sudo docker exec -ti ${GATEWAY_NAME} /app/providers.sh add ${DOCTORS}
}


# Run pdc-0000 and pdc-0000-db - for testing
#
docker_test ()
{
	# Verify ssh files are in order
	verify_ssh_files

	# Assign variables
	export GATEWAY_ID=${TEST_GATEWAY}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
	export DATABASE_NAME=${GATEWAY_NAME}-db
	export GATEWAY_PORT=`expr 40000 + ${GATEWAY_ID}`

	# Run a database and gateway
	sudo docker run -d --name ${DATABASE_NAME} -h ${DATABASE_NAME} --restart='always' -v ${SCRIPT_DIR}/util/:/util/:ro mongo --storageEngine wiredTiger || echo ${DATABASE_NAME} exists!

	# Run a gateway
	inform_exec "Running test gateway" \
		"sudo docker run -d --name ${GATEWAY_NAME} -h ${GATEWAY_NAME} --link ${DATABASE_NAME}:database -e gID=${GATEWAY_ID} -p ${GATEWAY_PORT}:3001 --env-file=config.env --restart='always' ${DOCKER_ENDPOINT} ${DOCKER_REPO_NAME}"

	# Import sample data
	sleep 2
	sudo docker exec -ti ${DATABASE_NAME} /util/sample10/import.sh

	# Inspect container
	inform_exec "Inspecting container" \
		"sudo docker inspect ${GATEWAY_NAME}"

	# Tail logs
	echo "Press Enter when to tail logs and/or ctrl-C to cancel"
	read ENTER_HERE
	inform_exec "Tailing logs" \
		"sudo docker logs -f ${GATEWAY_NAME}"
}


# Run a Docker gateway container
#
docker_rm ()
{
	docker rm --help
	echo
	echo
	echo "To minimize errors this has not been scripted."
	echo
	echo
}


# Modify a gateway's providers whitelist
#
docker_providers ()
{
	# Check and assign parameters
	[ $# -eq 3 ]|| \
		usage_error "providers [add|remove] [Gateway ID#] [CPSID#1,CPSID#1,...,CPSID#n]"
	#
	export ADD_REMOVE=${1}
	export GATEWAY_ID=${2}
	export DOCTORS=${3}
	#
	# Exception for pdc-0000
	[ ${GATEWAY_ID} -eq 0 ]|| verify_gateway_id ${GATEWAY_ID}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})

	# Pass parameters to providers.sh on gateway
	inform_exec "Modifying providers for ${GATEWAY_NAME}" \
		"sudo docker exec -ti ${GATEWAY_NAME} /sbin/setuser app /app/providers.sh ${ADD_REMOVE} ${DOCTORS}"
}


# Save (export) the current gateway and mongo images to tar files
#
docker_save ()
{
	GATEWAY_OUT="${SCRIPT_DIR}/${DOCKER_SAVE_NAME}.tar"
	DATABASE_OUT="${SCRIPT_DIR}/${DOCKER_SAVE_NAME}-db.tar"
	#
	inform_exec "Saving gateway image" "sudo docker save -o ${GATEWAY_OUT} ${DOCKER_REPO_NAME}"
	inform_exec "Saving gateway image" "sudo docker save -o ${DATABASE_OUT} mongo"
}


# Load (import) pdc.io-gateway.tar as the new gateway image
#
docker_load ()
{
	# Verify input file is present
	GATEWAY_IN="${SCRIPT_DIR}/${DOCKER_SAVE_NAME}.tar"
	DATABASE_IN="${SCRIPT_DIR}/${DOCKER_SAVE_NAME}-db"
	#
	verify_condition "[ -f ${GATEWAY_IN} ]" \
		"Verify ${GATEWAY_IN} is present"
	verify_condition "[ -f ${DATABASE_IN} ]" \
		"Verify ${DATABASE_IN} is present"
	#
	inform_exec "Loading gateway image" "sudo docker load -i ${GATEWAY_IN}"
	inform_exec "Loading gateway image" "sudo docker load -i ${DATABASE_IN}"
}


docker_configure ()
{
	# Install Docker, if necessary
	#
	( which docker )|| \
		( \
			sudo apt-get update
			sudo apt-get install -y linux-image-extra-$(uname -r); \
			sudo modprobe aufs; \
			wget -qO- https://get.docker.com/ | sh; \
		)

	# Configure MongoDB
	#
	( echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled )> /dev/null
	( echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag )> /dev/null

	# Configure ~/.bashrc, if necessary
	#
	if(! grep --quiet 'function dockin()' ${HOME}/.bashrc ); \
	then \
		( \
			echo ''; \
			echo '# Function to quickly enter containers'; \
			echo '#'; \
			echo 'function dockin()'; \
			echo '{'; \
			echo '  if [ $# -eq 0 ]'; \
			echo '  then'; \
			echo '		echo "Please pass a docker container to enter"'; \
			echo '		echo "Usage: dockin [containerToEnter]"'; \
			echo '	else'; \
			echo '		sudo docker exec -it $1 /bin/bash'; \
			echo '	fi'; \
			echo '}'; \
			echo ''; \
			echo '# Aliases to frequently used functions and applications'; \
			echo '#'; \
			echo "alias c='dockin'"; \
			echo "alias d='sudo docker'"; \
			echo "alias e='sudo docker exec'"; \
			echo "alias i='sudo docker inspect'"; \
			echo "alias l='sudo docker logs -f'"; \
			echo "alias p='sudo docker ps -a'"; \
			echo "alias s='sudo docker ps -a | less -S'"; \
		) | tee -a ${HOME}/.bashrc; \
		echo ""; \
		echo ""; \
		echo "Please log in/out for changes to take effect!"; \
		echo ""; \
	fi
}


################################################################################
# Main - parameters and executions start here!
################################################################################


# Expected input
#
# $0 this script
# $1 Command: e.g. build, add, remove
# $2 Option: e.g. nothing, gateway ID, image name
# $3 Argument: e.g. nothing, doctor IDs, output path


# Set variables from parameters, prompt when password not provided
#
export COMMAND=${1:-""}
export OPTION=${2:-""}
export ARG_1=${3:-""}
export ARG_2=${4:-""}


# Get script directory and source config.env
#
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SCRIPT_DIR}/config.env


# If DNS is disabled (,, = lowercase, bash 4+), then use --dns-search=.
#
[ "${DNS_DISABLE,,}" != "yes" ] || \
	export DOCKER_ENDPOINT="${DOCKER_ENDPOINT} --dns-search=."


# Run based on command
#
case "${COMMAND}" in
	"build"       ) docker_build;;
	"run"         ) docker_run ${OPTION} ${ARG_1};;
	"test"        ) docker_test;;
	"rm"          ) docker_rm;;
	"save"        ) docker_save;;
	"load"        ) docker_load;;
	"providers"   ) docker_providers ${OPTION} ${ARG_1} ${ARG_2};;
	"configure"   ) docker_configure;;
	"keygen"      ) create_ssh_files;;
	*             ) usage_help
esac
