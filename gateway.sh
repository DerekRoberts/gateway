#!/bin/bash
#
# Halt on errors or uninitialized variables
#
set -e -o nounset


# Expected input
#
# $0 this script
# $1 Command: build, add, remove
# $2 Gateway ID#
# $3 Doctor (clinician) IDs (separated by commas)


# Check parameters
#
if([ $# -lt 1 ]||[ $# -gt 3 ])
then
	echo
	echo "Unexpected number of parameters."
	echo
	echo "Usage: gateway.sh [build|add|import|export] [OPTIONS] [arg...]"
	echo
	exit
fi


# Set variables from parameters, prompt when password not provided
#
export COMMAND=${1}
export GATEWAY_ID=${2:-1000000000}
export GATEWAY_NAME=pdc-$(printf "%04d" ${GATEWAY_ID})
export OPTION=${3:-excluded}
export ARGUMENT=${4:-excluded}


# Get script directory and target file
#
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# Pull in variables from config.env
#
source ${SCRIPT_DIR}/config.env


docker_build ()
{
	echo
	echo "*** Building gateway *** sudo docker build -t pdc.io/gateway . ***"
	echo
	sudo docker build -t pdc.io/gateway .
	echo
	echo
	exit
}

docker_run ()
{
	if [[ $1 =~ ^[0-9]+$ ]]&&[ $1 -gt 0 ]&&[ $1 -lt 1000 ]
	then
		echo
		echo "*** Running gateway *** sudo docker run -d --name $2 -h $2 -e gID=$1 --env-file=config.env --restart='always' $3 pdc.io/gateway ***"
		echo
		sudo docker run -d --name $2 -h $2 -e gID=$1 --env-file=config.env --restart='always' $3 pdc.io/gateway
	else
		echo $1 is not a valid Gateway ID number
		exit
	fi
}

docker_providers_add ()
{
	echo
	echo "*** Adding providers to $1 *** sudo docker exec -ti $1 /sbin/setuser app /app/providers.sh remove $2"
	echo
	sudo docker exec -ti $1 /sbin/setuser app /app/providers.sh add $2
}

docker_providers_remove ()
{
	echo
	echo "*** Removing providers from $1 *** sudo docker exec -ti $1 /sbin/setuser app /app/providers.sh remove $2"
	echo
	sudo docker exec -ti $1 /sbin/setuser app /app/providers.sh remove $2
}

docker_export ()
{
	echo
	echo "*** Exporting gateway *** sudo docker save Export Coming Soon ***"
	echo
}

docker_import ()
{
	echo
	echo "*** Import Coming Soon ***"
	echo
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
			echo "alias m='make'"; \
			echo "alias ggraph='git log --oneline --graph --decorate --color'"; \
		) | tee -a ${HOME}/.bashrc; \
		echo ""; \
		echo ""; \
		echo "Please log in/out for changes to take effect!"; \
		echo ""; \
	fi
}


# Run based on command
#
if [ "${COMMAND}" = "build" ]
then
	docker_build
elif [ "${COMMAND}" = "add" ]
then
	docker_run ${GATEWAY_ID} ${GATEWAY_NAME} "${DOCKER_ENDPOINT}"
elif [ "${COMMAND}" = "providers-add" ]
then
	docker_providers_add ${GATEWAY_NAME} ${OPTION}
elif [ "${COMMAND}" = "providers-remove" ]
then
	docker_providers_remove ${GATEWAY_NAME} ${OPTION}
elif [ "${COMMAND}" = "export" ]
then
	echo
	echo "*** Export Coming Soon ***"
elif [ "${COMMAND}" = "import" ]
then
	echo
	echo "*** Import Coming Soon ***"
elif [ "${COMMAND}" = "configure" ]
then
	docker_configure
else
	echo "Error!"
	exit
fi



#	pdc-$(printf "%04d" $1)
