# Dockerfile for the HDC's Gateway Service
#
# Part of an Endpoint deployment
#
#
# Receives E2E formatted XML, stores deidentified in a pre-existing MongoDb
# container and responds to aggreate data queries.
#
# Requires pre-configured and pre-approved SSH keys.  Contact admin@pdcbc.ca.
#
# Example:
# sudo docker pull mongo:3.2.9
# sudo docker pull hdcbc/gateway:latest
# sudo docker run -d --restart=always --name=gateway_db \
#   -v <local path>:/data/db/ \
#   mongo:3.2.9
# sudo docker run -d --restart=always --name=gateway \
#   -v <local path>:/home/autossh/.ssh/ \
#   -e GATEWAY_ID=9999 \
#   -e DOCTOR_IDS=11111,22222,...,99999 \
#   --link gateway_db:database \
#   hdcbc/gateway:latest
#
#
FROM phusion/passenger-ruby19
MAINTAINER derek.roberts@gmail.com


################################################################################
# System
################################################################################


# Environment variables, users and packages
#
ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive
RUN adduser --disabled-password --gecos '' autossh
RUN apt-get update; \
    apt-get install --no-install-recommends -y \
      autossh\
      mongodb-clients; \
    apt-get autoclean; \
    apt-get clean; \
    rm -rf \
      /var/tmp/* \
      /var/lib/apt/lists/* \
      /tmp/* \
      /usr/share/doc/ \
      /usr/share/doc-base/ \
      /usr/share/man/


################################################################################
# Application
################################################################################


# Prepare /gateway/ folder, point mongoid.yml to container and run install
#
WORKDIR /gateway/
COPY . .
RUN sed -i 's/localhost/database/' config/mongoid.yml
RUN mkdir -p ./tmp/pids ./util/files; \
    gem install multipart-post; \
    chown -R app:app /gateway/; \
    /sbin/setuser app bundle install --path vendor/bundle


################################################################################
# Runit Service Scripts
################################################################################


# Startup - autossh tunnel
#
RUN SERVICE=autossh;\
    mkdir -p /etc/service/${SERVICE}/; \
    SCRIPT=/etc/service/${SERVICE}/run; \
    ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Set variables"; \
      echo "#"; \
      echo "GATEWAY_ID=\${GATEWAY_ID:-0}"; \
      echo "TEST_OPT_IN=\${TEST_OPT_IN:-no}"; \
      echo "#"; \
      echo "IP_COMPOSER=\${IP_COMPOSER:-142.104.128.120}"; \
      echo "IP_TEST_GRP=\${IP_TEST_GRP:-142.104.128.121}"; \
      echo "PORT_AUTOSSH=\${PORT_AUTOSSH:-2774}"; \
      echo "PORT_START_GATEWAY=\${PORT_START_GATEWAY:-40000}"; \
      echo "PORT_REMOTE=\`expr \${PORT_START_GATEWAY} + \${GATEWAY_ID}\`"; \
      echo ""; \
      echo ""; \
      echo "# Check for SSH keys, create if necessary"; \
      echo "#"; \
      echo "if [ ! -s /home/autossh/.ssh/id_rsa.pub ]"; \
      echo "then"; \
      echo "  chown -R autossh:autossh /home/autossh/"; \
      echo "  /sbin/setuser autossh ssh-keygen -b 4096 -t rsa -N \"\" -C ep\${GATEWAY_ID}-\$(date +%Y-%m-%d-%T) -f /home/autossh/.ssh/id_rsa"; \
      echo "fi"; \
      echo ""; \
      echo ""; \
      echo "# Start test autossh tunnel (requires opt-in), leave in background"; \
      echo "#"; \
      echo "if [ \${TEST_OPT_IN} == yes ]"; \
      echo "then"; \
      echo "  /sbin/setuser autossh /usr/bin/autossh \${IP_TEST_GRP} -p \${PORT_AUTOSSH} -N -R \${PORT_REMOTE}:localhost:3001 \\"; \
      echo "    -o ServerAliveInterval=60 -o Protocol=2 -o StrictHostKeyChecking=no -f"; \
      echo "fi"; \
      echo ""; \
      echo ""; \
      echo "# Export PID variable and stop any autossh instances"; \
      echo "#"; \
      echo "export AUTOSSH_PIDFILE=/home/autossh/autossh.pid"; \
      echo "if [ -s \${AUTOSSH_PIDFILE} ]"; \
      echo "then"; \
      echo "  kill cat \${AUTOSSH_PIDFILE} || true"; \
      echo "  rm \${AUTOSSH_PIDFILE}"; \
      echo "fi"; \
      echo ""; \
      echo ""; \
      echo "# Start primary autossh tunnel, keep in foreground"; \
      echo "#"; \
      echo "/sbin/setuser autossh /usr/bin/autossh \${IP_COMPOSER} -p \${PORT_AUTOSSH} -N -R \${PORT_REMOTE}:localhost:3001 \\"; \
      echo "  -o ServerAliveInterval=30 -o Protocol=2 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no"; \
      echo ""; \
      echo ""; \
      echo "# If connection has failed, provide direction"; \
      echo "#"; \
      echo "cat /home/autossh/.ssh/id_rsa.pub"; \
      echo "echo"; \
      echo "echo 'AutoSSH not connected.  Please provide /home/autossh/.ssh/id_rsa.pub (above),'"; \
      echo "echo 'a list of participating CPSIDs and all paperwork to the PDC at admin@pdcbc.ca'"; \
      echo "sleep 60"; \
      )  \
        >> ${SCRIPT}; \
    	chmod +x ${SCRIPT}


# Startup - gateway delayed job
#
RUN SERVICE=delayed_job;\
    mkdir -p /etc/service/${SERVICE}/; \
    SCRIPT=/etc/service/${SERVICE}/run; \
    ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Start delayed job"; \
      echo "#"; \
      echo "cd /gateway/"; \
      echo "/sbin/setuser app bundle exec /gateway/script/delayed_job stop > /dev/null"; \
      echo "[ ! -s /gateway/tmp/pids/server.pid ]|| rm /gateway/tmp/pids/server.pid"; \
      echo "echo 'Starting delayed_job'"; \
      echo "exec /sbin/setuser app bundle exec /gateway/script/delayed_job run"; \
    )  \
      >> ${SCRIPT}; \
    chmod +x ${SCRIPT}


# Startup - gateway rails server
#
RUN SERVICE=rails;\
    mkdir -p /etc/service/${SERVICE}/; \
    SCRIPT=/etc/service/${SERVICE}/run; \
    ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Set variables"; \
      echo "#"; \
      echo "DOCTOR_IDS=\${DOCTOR_IDS:-cpsid}"; \
      echo ""; \
      echo ""; \
      echo "# Populate providers.txt with DOCTOR_IDS"; \
      echo "#"; \
      echo "/gateway/providers.sh add \${DOCTOR_IDS}"; \
      echo ""; \
      echo ""; \
      echo "# Start Rails server"; \
      echo "#"; \
      echo "cd /gateway/"; \
      echo "echo 'Starting rails'"; \
      echo "exec /sbin/setuser app bundle exec rails server -p 3001"; \
    )  \
      >> ${SCRIPT}; \
    chmod +x ${SCRIPT}


################################################################################
# Test and Maintenance Scripts
################################################################################


# SSH test
#
RUN SCRIPT=/ssh_test.sh; \
    ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Attempt to connect autossh tunnel and notify user"; \
      echo "#"; \
      echo "sleep 5"; \
      echo "echo"; \
      echo "echo"; \
      echo "if [ \"\$( setuser autossh ssh -p 2774 -o StrictHostKeyChecking=no 142.104.128.120 /app/test/ssh_landing.sh )\" ]"; \
      echo "then"; \
      echo "  echo 'Connection successful!'"; \
      echo "  echo"; \
      echo "  echo ':D'"; \
      echo "else"; \
      echo "  cat /home/autossh/.ssh/id_rsa.pub"; \
      echo "  echo 'ERROR: unable to connect to 142.104.128.120'"; \
      echo "  echo"; \
      echo "  echo 'Please verify the ssh public key (above) has been provided to admin@pdcbc.ca.'"; \
      echo "fi"; \
      echo "echo"; \
      echo "echo"; \
    )  \
      >> ${SCRIPT}; \
    chmod +x ${SCRIPT}


# MongoDb maintenance
#
RUN SCRIPT=/db_maintenance.sh; \
( \
echo "#!/bin/bash"; \
echo ""; \
echo ""; \
echo "# Set index"; \
echo "#"; \
echo "/usr/bin/mongo database:27017/query_gateway_development --eval 'db.records.createIndex({ hash_id : 1 }, { unique : true })'"; \
echo ""; \
echo ""; \
echo "# Database junk cleanup"; \
echo "#"; \
echo "/usr/bin/mongo database:27017/query_gateway_development --eval 'db.providers.drop()'"; \
echo "/usr/bin/mongo database:27017/query_gateway_development --eval 'db.queries.drop()'"; \
echo "/usr/bin/mongo database:27017/query_gateway_development --eval 'db.results.drop()'"; \
)  \
>> ${SCRIPT}; \
chmod +x ${SCRIPT}; \
  ( \
    echo "# Run maintenance script (Sundays at noon)"; \
    echo "0 12 * * 0 "${SCRIPT}; \
  ) \
    | crontab -


################################################################################
# Volumes, ports and start command
################################################################################


# Volumes
#
VOLUME /home/autossh/.ssh/
RUN chown -R autossh:autossh /home/autossh/


# Initialize
#
WORKDIR /
CMD ["/sbin/my_init"]
