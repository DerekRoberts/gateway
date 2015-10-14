#!/bin/bash
#
# Exit on errors or unitialized variables
#
set -o nounset


# Change to script directory
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}


# Import sample 10 data
#
mongoimport --db query_gateway_development --collection records sample.json | grep imported
