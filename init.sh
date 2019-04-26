#!/bin/bash

sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get update
echo "Installing Docker-ce" >> /tmp/runner-$(date '+%Y%m%d').log
sudo apt-get -y install docker-ce
echo "Installing Ansible" >> /tmp/runner-$(date '+%Y%m%d').log
sudo apt-get install ansible -y

GITLAB_URL_RUNNER_PKG="https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh"
HOST=`hostname`;

GITLAB_TOKEN_RUNNER=$1
GITLAB_RUNNER_EXECUTOR=$2
GITLAB_URL=$3

if [ "x${GITLAB_URL}" = "x" ];
then
	GITLAB_URL="https://fala.cl"
fi

#Installing gitlab-runner 
echo "Installing runner on the VM provisioned"
curl -L ${GITLAB_URL_RUNNER_PKG} | sudo bash
sudo apt-get -y install gitlab-runner

#Unregistering gitlab-runner 
echo "Unregistering gitlab-runner" >> /tmp/runner-$(date '+%Y%m%d').log
sudo gitlab-runner unregister --all-runners

registerAsDocker(){
        echo "Registering runner as expected DOCKER executor ${GITLAB_URL} ${GITLAB_TOKEN_RUNNER}" 
        sudo gitlab-runner register \
          --non-interactive \
          --name "grunner-docker-${HOST}" \
          --url "${GITLAB_URL}/" \
          --registration-token "${GITLAB_TOKEN_RUNNER}" \
          --executor 'docker' \
          --locked="false" \
          --docker-privileged \
          --docker-image 'alpine:3.7'
}

registerAsShell(){
echo "Registering runner as default Shell executor ${GITLAB_URL} ${GITLAB_TOKEN_RUNNER}" >>/tmp/runner-$(date '+%Y%m%d').log
        sudo gitlab-runner register \
          --non-interactive \
          --name "grunner-shell-${HOST}" \
          --url "${GITLAB_URL}/" \
          --registration-token "${GITLAB_TOKEN_RUNNER}" \
          --executor "shell" \
          --run-untagged="true" \
          --locked="false"
}

if [ "x${GITLAB_RUNNER_EXECUTOR}" != "x" ];
then
        registerAsDocker;
else
        registerAsShell;
fi

#Restarting gitlab-runner
echo "Restarting gitlab-runner" >> /tmp/runner-$(date '+%Y%m%d').log
sudo gitlab-runner restart
