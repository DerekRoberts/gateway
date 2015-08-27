#!/bin/bash
#
# Halt on errors or uninitialized variables
#
set -e -o nounset


# Set 3rd_next folder
#
DIR=/home/pdcadmin/3rd_next


# Create directory
#
sudo mkdir -p ${DIR}
sudo chown -R pdcadmin:pdcadmin ${DIR}


# Populate 3rd_next folder
#
# Coming soon!  For now use a dummy file
#
TARGET=${DIR}/dummy.txt
if [ ! -s ${TARGET} ]
then
	echo "Filler!" | sudo tee ${TARGET}
fi


# Sync 3rd_next
#
sudo -u pdcadmin bash -c 'rsync -have "ssh -p 2774" ${DIR} autossh@hub.pdc.io:/home/autossh/'


# Add cron job
#
if((! sudo test -e /var/spool/cron/crontabs/pdcadmin )||(! sudo grep --quiet 'autossh@hub.pdc.io:/home/autossh/' /var/spool/cron/crontabs/pdcadmin )); \
then \
  ( \
    echo ''; \
    echo ''; \
    echo '# Export 3rd_next'; \
    echo '#'; \
    echo '30 3 * * * rsync -have "ssh -p 2774" '${DIR}' autossh@hub.pdc.io:/home/autossh/'; \
    echo ''; \
  ) | sudo tee -a /var/spool/cron/crontabs/pdcadmin; \
fi
