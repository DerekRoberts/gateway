#!/bin/bash
#
# Halt on errors or uninitialized variables
#
set -e -o nounset


# Expected input
#
# $0 this script
# $1 Doctor (clinician) ID


# Check parameters
#
if([ $# -ne 2 ])
then
	echo
	echo "Unexpected number of parameters."
	echo
	echo "Usage: providers_add.sh [add|remove] [doctor ID#1]"
	echo
	exit
fi


# Set variables from parameters, prompt when password not provided
#
export COMMAND=${1}
export DOCTORS=${2}


# Get script directory and target file
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TARGET=${DIR}/providers.txt


# Assign function based on COMMAND
#
if [ ${COMMAND} = "add" ]
then
	d_function ()
		{
			# Either the doctor is present or we add them
			( grep --quiet -o ^$1$ ${TARGET} )||( echo $1 | tee -a ${TARGET} )
		}
elif [ ${COMMAND} = "remove" ]
then
	d_function ()
	{
		# Either the doctor is absent or we remove them
		( ! grep --quiet ${d} ${TARGET} )||( sed -i /${d}/d ${TARGET} )
	}
else
	echo "Input not understood"
	exit
fi


# Parse and proess ${DOCTORS}
#
# Set bash's internal field separator (note: preassigned for whitespace)
IFS=','
for d in ${DOCTORS}
do
	if ! [[ ${d} =~ ^[0-9]{5}$ ]]
	then
		echo ${d} is not a valid CPSID
		echo ${d} >> PROVIDER_ERRORS.txt
	else
		d_function ${d}
	fi
done


echo "***"
cat ${TARGET}
