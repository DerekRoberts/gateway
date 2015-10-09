
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
	echo "This script creates Gateways in Docker containers"
	echo
	echo "Usage: ./gateway.sh COMMAND [arguments]"
	echo
	echo "Commands:"
	echo "	run         Run a new Gateway"
	echo "	test        Run and inspect a test Gateway"
	echo "	providers   Modify a Gateway's providers list"
	echo "	configure   Configures Docker, MongoDB and bash"
	echo "	keygen      Run a keyholder for SSH keys"
	echo "	develop     Build and test a local Dockerfile"
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
docker_keygen ()
{
	# Create data container for ssh details
	sudo docker run -d --name ${DATA_CONTAINER} -h ${DATA_CONTAINER} -v /home/autossh/.ssh/ --env-file=config.env --restart='always' phusion/baseimage

	# Echo public key
	echo
	echo "New SSH files generated.  Please take note of the public key."
	echo
	sudo docker exec ${DATA_CONTAINER} /bin/bash -c 'ssh-keygen -b 4096 -t rsa -N "" -C "$(whoami)@$(hostname)-$(date +"%Y-%m-%d-%T")" -f ~/.ssh/id_rsa'
	sudo docker exec ${DATA_CONTAINER} /bin/bash -c 'cat /root/.ssh/id_rsa.pub'
	echo
	echo

	# Test the key, generating a known_hosts file, otherwise remove container
	echo "Press enter when that key ready to test this key"
	echo
	read ENTER_TO_CONTINUE
	sudo docker exec -ti ${DATA_CONTAINER} /bin/bash -c 'ssh -p ${PORT_AUTOSSH} autossh@${IP_HUB} -o StrictHostKeyChecking=no "hostname; exit"'

	# Copy files to expected location
	sudo docker exec ${DATA_CONTAINER} /bin/bash -c 'mkdir -p /home/autossh/.ssh/'
	sudo docker exec ${DATA_CONTAINER} /bin/bash -c 'cp /root/.ssh/* /home/autossh/.ssh/'
	echo
	echo
	echo "Success!"
	echo
	echo
}


# Import Sample10 data
#
import_sample ()
{
	# Assign parameters
	[ $# -eq 1 ]|| \
		usage_error "sample10 [Database Container]"
	#
	export DATABASE_NAME=${1}

	# Import sample data (import.sh fails as error)
	sleep 2
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c "mkdir -p /sample_data/"
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c 'curl \
		https://raw.githubusercontent.com/PDCbc/gateway/master/util/sample10/sample.json \
		> /sample_data/sample.json'
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c 'curl \
		https://raw.githubusercontent.com/PDCbc/gateway/master/util/sample10/import.sh \
		> /sample_data/import.sh'
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c "chmod +x /sample_data/import.sh"
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c "/sample_data/import.sh" || true
}


# Run a gateway and database containers
#
docker_run ()
{
	# Verify transparent_hugepage and its defrag are disabled
	verify_condition "grep --quiet \[never\] /sys/kernel/mm/transparent_hugepage/enabled" "grep '\[never\]' /sys/kernel/mm/transparent_hugepage/enabled"
	verify_condition "grep --quiet \[never\] /sys/kernel/mm/transparent_hugepage/defrag" "Disable transparent hugepage's defrag"

	# Check parameters and assign variables
	[ $# -eq 1 ]||[ $# -eq 2 ]|| \
		usage_error "run [Gateway ID#] [optional: CPSID#1,CPSID#1,...,CPSID#n]"
	#
	export GATEWAY_ID=${1}
	export DOCTORS=${2:-""}
	#
	[ ${DOCTORS} = "cpsid" ] || verify_gateway_id ${GATEWAY_ID}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
	export DATABASE_NAME=${GATEWAY_NAME}-db
	export GATEWAY_PORT=`expr 40000 + ${GATEWAY_ID}`

	# Run a database and set the index (for duplicates)
	sudo docker run -d --name ${DATABASE_NAME} -h ${DATABASE_NAME} \
		--restart='always' mongo --storageEngine wiredTiger || \
		echo "NOTE: Updates should reuse existing databases"
	#
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c \
		"mongo query_gateway_development --eval \
  	'printjson( db.records.ensureIndex({ hash_id : 1 }, { unique : true }))'"

	# Run a gateway, deleting any old instances
	sudo docker rm -fv ${GATEWAY_NAME} || true
	inform_exec "Running gateway" \
		"sudo docker run -d --name ${GATEWAY_NAME} -h ${GATEWAY_NAME} \
			--link ${DATABASE_NAME}:database -e gID=${GATEWAY_ID} \
			-p ${GATEWAY_PORT}:3001 --volumes-from ${DATA_CONTAINER} \
			--env-file=config.env --restart='always' \
			${DOCKER_ENDPOINT} pdcbc/gateway"

	# If there are any CPSIDs, then pass them to the gateway
	[ ${DOCTORS} == "" ]|| \
		sudo docker exec -ti ${GATEWAY_NAME} /app/providers.sh add ${DOCTORS}
}


# Run pdc-0000 and pdc-0000-db - for testing
#
docker_test ()
{
	# Assign variables
	export GATEWAY_ID=${TEST_GATEWAY:-0}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
	export DATABASE_NAME=${GATEWAY_NAME}-db

	# Run a test gateway
	docker_run ${GATEWAY_ID} cpsid

	# Import sample data
	import_sample ${DATABASE_NAME}

	# Inspect container
	inform_exec "Inspecting container" \
		"sudo docker inspect ${GATEWAY_NAME}"

	# Tail logs
	echo "Press Enter when to tail logs and/or ctrl-C to cancel"
	read ENTER_HERE
	inform_exec "Tailing logs" \
		"sudo docker logs -f ${GATEWAY_NAME}"
}


# Build a Docker gateway image
#
docker_dev ()
{
	# W/o Internet build fails and destroys existing images
	inform_exec "Building gateway" "sudo docker build -t local/gateway ."
	sudo docker pull mongo

	# Verify transparent_hugepage and its defrag are disabled
	verify_condition "grep --quiet \[never\] /sys/kernel/mm/transparent_hugepage/enabled" "grep '\[never\]' /sys/kernel/mm/transparent_hugepage/enabled"
	verify_condition "grep --quiet \[never\] /sys/kernel/mm/transparent_hugepage/defrag" "Disable transparent hugepage's defrag"

	# Assign variables
	export GATEWAY_ID=${TEST_GATEWAY:-0}
	export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
	export DATABASE_NAME=${GATEWAY_NAME}-db
	export GATEWAY_PORT=`expr 40000 + ${GATEWAY_ID}`

	# Run a database and set the index (for duplicates)
	sudo docker run -d --name ${DATABASE_NAME} -h ${DATABASE_NAME} \
		--restart='always' mongo --storageEngine wiredTiger || \
		echo "NOTE: Updates should reuse existing databases"
	#
	sudo docker exec -ti ${DATABASE_NAME} /bin/bash -c \
		"mongo query_gateway_development --eval \
  	'printjson( db.records.ensureIndex({ hash_id : 1 }, { unique : true }))'"

	# Run an endpoint, removing any previous versions
	sudo docker rm -fv ${GATEWAY_NAME} || true
	inform_exec "Running gateway" \
		"sudo docker run -d --name ${GATEWAY_NAME} -h ${GATEWAY_NAME} \
			--link ${DATABASE_NAME}:database -e gID=${GATEWAY_ID} \
			-p ${GATEWAY_PORT}:3001 --volumes-from ${DATA_CONTAINER} \
			--env-file=config.env --restart='always' \
			${DOCKER_ENDPOINT} local/gateway"

	# Import sample data
	import_sample ${DATABASE_NAME}

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


docker_configure ()
{
	# Install Docker, if necessary
	( which docker )|| \
		( \
			sudo apt-get update
			sudo apt-get install -y linux-image-extra-$(uname -r); \
			sudo modprobe aufs; \
			wget -qO- https://get.docker.com/ | sh; \
		)

	# Disable Transparent Hugepages for MongoDB, while running
	echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
	echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag


	# Disable Transparent Hugepage for MongoDB, after reboots
	if(! grep --quiet 'never > /sys/kernel/mm/transparent_hugepage/enabled' /etc/rc.local ); \
	then \
		sudo sed -i '/exit 0/d' /etc/rc.local; \
		( \
			echo ''; \
			echo '# Disable Transparent Hugepage, for Mongo'; \
			echo '#'; \
			echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'; \
			echo 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'; \
			echo ''; \
			echo 'exit 0'; \
		) | sudo tee -a /etc/rc.local; \
	fi
	sudo chmod 755 /etc/rc.local


	# Configure ~/.bashrc, if necessary
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
# $1 Command: e.g. test, run, remove
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
	"run"         ) docker_run ${OPTION} ${ARG_1};;
	"test"        ) docker_test;;
	"providers"   ) docker_providers ${OPTION} ${ARG_1} ${ARG_2};;
	"configure"   ) docker_configure;;
	"keygen"      ) docker_keygen;;
	"develop"     ) docker_dev;;
	*             ) usage_help
esac