#!/bin/bash
#
# Halt on errors or uninitialized variables
#
set -e -o nounset


# Expected input
#
# $0 this script
# $1 Doctor (clinician) IDs (separated by commas)


# Check parameters
#
if([ $# -lt 1 ]||[ $# -gt 1 ])
then
	echo
	echo "Unexpected number of parameters."
	echo
	echo "Usage: providers_add.sh [docID #1],[docID #2],...,[docID #n]"
	echo
	exit
fi


# Set variables from parameters
#
DOCTORS=${1}


# Get script directory and target file
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TARGET=${DIR}/providers.txt


# Parse ${DOCTORS} by changing bash's internal field separator
# Note: IFS is preassigned for whitespace
#
IFS=','
for d in ${DOCTORS}
do
	echo ${d} | tee -a ${TARGET}
done
