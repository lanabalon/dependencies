#!/bin/bash


sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get update
echo "Installing Docker-ce" >> /tmp/runner.log
sudo apt-get -y install docker-ce
echo "Installing Ansible" >> /tmp/runner.log
sudo apt-get install ansible -y


GITLAB_URL_RUNNER_PKG="https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh"

GITLAB_TOKEN_RUNNER=$1
GITLAB_RUNNER_EXECUTOR=$2
GITLAB_URL=$3

if [ "x${GITLAB_URL}" != "x" ];
then
	GITLAB_URL="https://fala.cl"
fi

#Installing gitlab-runner 
echo "Installing gitlab-runner" > /tmp/runner.log
curl -L ${GITLAB_URL_RUNNER_PKG} | sudo bash
sudo apt-get -y install gitlab-runner

#Unregistering gitlab-runner 
echo "Unregistering gitlab-runner" >> /tmp/runner.log
sudo gitlab-runner unregister --all-runners

registerAsDocker(){
	echo "Registering runner as expected DOCKER executor" >> /tmp/runner.log
	sudo gitlab-runner register \
	  --non-interactive \
	  --name "gitlab-runner-${HOSTNAME}" \
	  --url "https://${GITLAB_URL}/" \
	  --registration-token "${GITLAB_TOKEN_RUNNER}" \
	  --executor docker \
	  --tag-list 'project_gitlab-runner' \
	  --run-untagged="true" \
	  --limit 4 \ 
	  --locked="false" \
	  --docker-image 'alpine:3.7' \ 
	  --docker-tlsverify false \ 
	  --docker-privileged true
	#  --docker-cpus 4 --docker-memory 8g \ 
	#  --cache-type s3 --cache-s3-server-address 'asdasdasd' \
	#  --cache-s3-access-key 'asdasdasd' --cache-s3-secret-key 'asdasdasd' \
	#  --cache-s3-bucket-name 'swarmcache' --cache-s3-insecure false \ 
	#  --cache-s3-cache-path 'swarmcache/' --cache-cache-shared true \
	#  --docker-cert-path /etc/gitlab-runner
}

registerAsShell(){
echo "Registering runner as default Shell executor" >> /tmp/runner.log
	sudo gitlab-runner register \
	  --non-interactive \
	  --name "gitlab-runner-${HOSTNAME}" \
	  --url "https://${GITLAB_URL}/" \
	  --registration-token "${GITLAB_TOKEN_RUNNER}" \
	  --executor "shell" \
	  --tag-list "project_gitlab-runner" \
	  --run-untagged="false" \
	  --limit="4" \
	  --locked="true"
}

if [ "x${GITLAB_RUNNER_EXECUTOR}" != "x" ];
then
	registerAsDocker;
else 
	registerAsShell;
fi

#Restarting gitlab-runner
echo "Restarting gitlab-runner" >> /tmp/runner.log
sudo gitlab-runner restart

