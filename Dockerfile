# Dockerfile for the PDC's Gateway (formerly Endpoint) service
#
#
# Receives e2e exports and responds to queries as part of an Endpoint deployment.
# Links to a database.
#
# Example:
# sudo docker pull pdcbc/gateway
# sudo docker run -d --name=gateway --restart=always \
#   --link database:database \
#   -v /encrypted/docker/import/.ssh/:/home/autossh/.ssh/:rw"
#   -e gID=9999 \
#   -e DOCTOR_IDS=11111,99999
#   pdcbc/dclapi
#
# Linked containers
# - Database:     --link database:database
#
# Folder paths
# - SSH keys:     -v </path/>:/home/autossh/.ssh/:ro
#
# Required variables
# - Gateway ID:   -e gID=####
# - Doctor IDs:   -e DOCTOR_IDS=#####,#####,...,#####
#
# Modify default settings
# - Composer IP:  -e IP_COMPOSER=#.#.#.#
# - AutoSSH port: -e PORT_AUTOSSH=####
# - Low GW port:  -e PORT_START_GATEWAY=####
#
#
FROM phusion/passenger-ruby19
MAINTAINER derek.roberts@gmail.com


# Update system and packages
#
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; \
    apt-get install -y \
      autossh; \
    apt-get autoclean; \
    apt-get clean; \
    rm -rf \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/* \
      /usr/share/doc/ \
      /usr/share/doc-base/ \
      /usr/share/man/


# Prepare /app/ folder
#
WORKDIR /app/
COPY . .
RUN mkdir -p ./tmp/pids ./util/files; \
    sed -i -e "s/localhost:27017/database:27017/" config/mongoid.yml; \
    gem install multipart-post; \
    chown -R app:app /app/; \
    /sbin/setuser app bundle install --path vendor/bundle


# Add AutoSSH User
#
RUN adduser --disabled-password --gecos '' --home /home/autossh autossh; \
    chown -R autossh:autossh /home/autossh


# Startup script for Gateway tunnel
#
RUN SRV=autossh; \
    mkdir -p /etc/service/${SRV}/; \
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
      echo "IP_TESTCPSR=\${IP_TESTCPSR:-142.104.128.121}"; \
      echo "PORT_AUTOSSH=\${PORT_AUTOSSH:-2774}"; \
      echo "PORT_START_GATEWAY=\${PORT_START_GATEWAY:-40000}"; \
      echo "PORT_REMOTE=\`expr \${PORT_START_GATEWAY} + \${GATEWAY_ID}\`"; \
      echo ""; \
      echo ""; \
      echo "# Check for SSH keys"; \
      echo "#"; \
      echo "sleep 5"; \
      echo "chown -R autossh:autossh /home/autossh"; \
      echo "if [ ! -s /home/autossh/.ssh/id_rsa.pub ]"; \
      echo "then"; \
      echo "  echo"; \
      echo "  echo No SSH keys in /home/autossh/.ssh/."; \
      echo "  echo"; \
      echo "  sleep 3600"; \
      echo "  exit"; \
      echo "fi"; \
      echo ""; \
      echo ""; \
      echo "# Start tunnels"; \
      echo "#"; \
      echo "export AUTOSSH_MAXSTART=1"; \
      echo "#"; \
      echo "if [ \${TEST_OPT_IN} == yes ]"; \
      echo "then"; \
      echo "  export AUTOSSH_MAXSTART=2"; \
      echo "  /sbin/setuser autossh /usr/bin/autossh \${IP_TESTCPSR} -p \${PORT_AUTOSSH} \\"; \
      echo "    -N -R \${PORT_REMOTE}:localhost:3001 -o ServerAliveInterval=15 -o Protocol=2 \\"; \
      echo "    -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -v &"; \
      echo "  sleep 5"; \
      echo "fi"; \
      echo "#"; \
      echo "exec /sbin/setuser autossh /usr/bin/autossh \${IP_COMPOSER} -p \${PORT_AUTOSSH} \\"; \
      echo "  -N -R \${PORT_REMOTE}:localhost:3001 -o ServerAliveInterval=15 -o Protocol=2\\"; \
      echo "  -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes"; \
    )  \
      >> /etc/service/${SRV}/run; \
    chmod +x /etc/service/${SRV}/run


# Startup script for Gateway's delayed job
#
RUN SRV=delayed_job; \
    mkdir -p /etc/service/${SRV}/; \
    ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Start delayed job"; \
      echo "#"; \
      echo "cd /app/"; \
      echo "/sbin/setuser app bundle exec /app/script/delayed_job stop > /dev/null"; \
      echo "rm /app/tmp/pids/server.pid > /dev/null"; \
      echo "exec /sbin/setuser app bundle exec /app/script/delayed_job run"; \
    )  \
      >> /etc/service/${SRV}/run; \
    chmod +x /etc/service/${SRV}/run


# Startup script for Rails server
#
RUN SRV=rails; \
    mkdir -p /etc/service/${SRV}/; \
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
      echo "/app/providers.sh add \${DOCTOR_IDS}"; \
      echo ""; \
      echo ""; \
      echo "# Start Rails server"; \
      echo "#"; \
      echo "cd /app/"; \
      echo "exec /sbin/setuser app bundle exec rails server -p 3001"; \
    )  \
      >> /etc/service/${SRV}/run; \
    chmod +x /etc/service/${SRV}/run


# Volume and port
#
VOLUME /home/autossh/.ssh/
EXPOSE 3001


# Run initialization command
#
CMD ["/sbin/my_init"]
