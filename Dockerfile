# Dockerfile for the PDC's Endpoint service
#
# Base image
#
FROM phusion/passenger-ruby19


# Update system, install AuthSSH, Lynx and UnZip
#
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'Dpkg::Options{ "--force-confdef"; "--force-confold" }' \
      >> /etc/apt/apt.conf.d/local
RUN apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y \
      autossh \
      lynx \
      mongodb \
      nano \
      rsync \
      unzip; \
    apt-get clean autoclean autoremove -y


# Start script for MongoDB
#
RUN mkdir -p /etc/service/mongodb/
RUN ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Start MongoDB"; \
      echo "#"; \
      echo "mkdir -p /var/lib/mongodb/"; \
      echo "mkdir -p /data/db/"; \
      echo "exec mongod --smallfiles"; \
    )  \
    >> /etc/service/mongodb/run
RUN chmod +x /etc/service/mongodb/run


# Startup script for Gateway tunnel
#
RUN mkdir -p /etc/service/autossh/
RUN ( \
      echo "#!/bin/bash"; \
      echo "set -x -e -o nounset"; \
      echo ""; \
      echo "# Create AutoSSH user"; \
      echo "#"; \
      echo "WHO=\${AUTOSSH_INITIATOR}"; \
      echo "getent passwd \${WHO} || adduser --disabled-password --gecos '' \${WHO}"; \
      echo "chown -R \${WHO}:\${WHO} /home/\${WHO}"; \
      echo ""; \
      echo ""; \
      echo "# Start tunnels"; \
      echo "#"; \
      echo "export AUTOSSH_PIDFILE=/home/\${WHO}/autossh_gateway.pid"; \
      echo "PORT_REMOTE=\`expr \${PORT_START_GATEWAY} + \${gID}\`"; \
      echo "#"; \
      echo "exec /sbin/setuser \${WHO} /usr/bin/autossh -M0 -p \${PORT_AUTOSSH} -N -R \${PORT_REMOTE}:localhost:3001 \${AUTOSSH_RECEIVER}@\${IP_HUB} -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o Protocol=2 -o ExitOnForwardFailure=yes -v"; \
    )  \
    >> /etc/service/autossh/run
RUN chmod +x /etc/service/autossh/run


# Startup script for Gateway app
#
RUN mkdir -p /etc/service/app/
RUN ( \
      echo "#!/bin/bash"; \
      echo ""; \
      echo ""; \
      echo "# Start Endpoint, retrying once every hour"; \
      echo "#"; \
      echo "cd /app/"; \
      echo "/sbin/setuser app bundle exec script/delayed_job start"; \
      echo "exec /sbin/setuser app bundle exec rails server -p 3001"; \
      echo "/sbin/setuser app bundle exec script/delayed_job stop"; \
    )  \
    >> /etc/service/app/run
RUN chmod +x /etc/service/app/run


# Prepare /app/ folder
#
WORKDIR /app/
COPY . .
RUN mkdir -p ./tmp/pids ./util/files
RUN gem install multipart-post
RUN chown -R app:app /app/
USER app
RUN bundle install --path vendor/bundle


# Run initialization command
#
USER root
CMD ["/sbin/my_init"]
