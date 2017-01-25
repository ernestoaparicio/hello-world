FROM ubuntu:14.04

RUN mkdir /home/meteorapp
ENV WORKDIR /home/meteorapp
ENV JENKINS_APP /jenkins/workspace/hello-world
ADD . .${JENKINS_APP}

# Do basic updates
RUN apt-get update -q && apt-get clean

# Install Python and Basic Python Tools for binary rebuilds of NPM packages
RUN apt-get install -y python python-dev python-distribute python-pip

# Move meteorapp
RUN mv ${JENKINS_APP} ${WORKDIR}/meteorapp

# Get curl in order to download curl
RUN apt-get install curl -y \
    # Install Meteor
    &&  (curl https://install.meteor.com?release=1.4.1.1 | sh) \
    &&  cd ${WORKDIR}/meteorapp \
    # Install the version of Node.js we need. (pegging it to 4.4.7 as we are installing before meteor build)
    && bash -c 'curl "https://nodejs.org/dist/v4.4.7/node-v4.4.7-linux-x64.tar.gz" > ${WORKDIR}/meteorapp/required-node-linux-x64.tar.gz' \
    && cd /usr/local && tar --strip-components 1 -xzf ${WORKDIR}/meteorapp/required-node-linux-x64.tar.gz

RUN ls ${WORKDIR}/meteorapp

RUN rm ${WORKDIR}/meteorapp/required-node-linux-x64.tar.gz
    
    # Build the NPM packages needed for build
    #&& cd ${WORKDIR}/meteorapp \
    #&& npm install \

    # Build the Meteor app
RUN cd ${WORKDIR}/meteorapp \
    && meteor build --verbose ../build --directory \
    && cd ${WORKDIR}/build/bundle/programs/server \
    && npm install \
    # Get rid of Meteor. We're done with it.
    && rm /usr/local/bin/meteor \
    && rm -rf ~/.meteor \
    #no longer need curl
    && apt-get --purge autoremove curl -y

RUN npm install -g forever

EXPOSE 80
ENV PORT 80

CMD ["forever", "--minUptime", "1000", "--spinSleepTime", "1000", "build/bundle/main.js"]