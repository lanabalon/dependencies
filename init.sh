#!/bin/bash

TAG=''
LOCKED=''
EXECUTOR=''
TOKEN=''
URL=''
CMDFILE="runner_register_exec"
DOCKIMG="alpine:3.7"

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

function install_docker {
  log_info "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get -y install docker-ce
}

function unregister_gitlab_runner {
  log_info "Unregister gitlab-runner"
  sudo gitlab-runner unregister --all-runners
}

function install_gitlab_runner {
  log_info "Installing gitlab-runner"
  curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
  sudo apt-get -y install gitlab-runner
}

function install_ansible {
  log_info "Installing ansible"
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt-get install ansible -y
}

function install_dependencies {
  log_info "Installing dependencies"
  sudo apt-get update -y
  sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
}

function register_gitlab_runner {
  log_info "Register gitlab-runner"
  HOST=`hostname`;

  {
        echo "#!/bin/bash"
        echo "  sudo gitlab-runner register \ "
        echo "    --non-interactive \ "
        echo "    --name \"grunner-${EXECUTOR}-${HOST}\" \ "
        echo "    --url \"${URL}/\" \ "
        echo "    --registration-token \"${TOKEN}\" \ "
        echo "    --executor \"${EXECUTOR}\" \ "
  } >> ${CMDFILE}.tpl
}

function register_gitlab_runner_tag {
if [ "x${TAG}" != "x" ]; then
  {
        echo "    --tag-list \"${TAG}\" \ "
        echo "    --run-untagged=\"false\" \ "
  } >> ${CMDFILE}.tpl
else
  {
        echo "    --run-untagged=\"yes\" \ "
  } >> ${CMDFILE}.tpl

fi

}

function register_gitlab_docker {

  {
        echo "    --docker-privileged \ "
        echo "    --docker-image \"${DOCKIMG}\" \ "
  } >> ${CMDFILE}.tpl
}

function register_gitlab_locked {

  {
        echo "    --locked=\"${LOCKED}\" \ "
  } >> ${CMDFILE}.tpl
}

function print_usage {
  echo
  echo "Usage: shell [OPTIONS]"
  echo
  echo "This script can be used to register gitlab-runner process against gitlab server. This script has been tested with Ubuntu 16.04x."
  echo
  echo "Options:"
  echo
  echo -e "  --locked\t\t register gitlab-runner with locked flag. Run just for projet owner of token."
  echo -e "  --tag\t\t register gitlab-runner with tag. Run the CI/CD just for job with the tag."
  echo -e "  --executor\t\t register gitlab-runner with executor of job. Run the CI/CD under shell, docker...."
  echo -e "  --token\t\t register gitlab-runner with token. Token its required, please take this value from gitlab."
  echo -e "  --url\t\t register gitlab-runner againts url of gitlab server. Url its required, please request this value to your admin."
  echo
  echo "Example:"
  echo
  echo "  runner-register.sh --url https://your-gitlab-server --token your-gitlab-project-token --executor your-prefered-executor-cicd --tag your-tag-separated-with-commas --locked [true|false]"
}

parse_args() {
    case "$1" in
        --locked)
            LOCKED="$2"
            ;;
        --tag)
            TAG="$2"
            ;;
        --executor)
            EXECUTOR="$2"
            ;;
        --token)
            TOKEN="$2"
            ;;
        --url)
            URL="$2"
            ;;
        *)
            echo "Unknown or badly placed parameter '$1'." 1>&2
            print_usage
            exit 1
            ;;
    esac
}

while [[ "$#" -ge 2 ]]; do
    psecond=$2;
    if [[ "$psecond" == "--"* ]];then
      parse_args "$1" ""
      shift; 
    else
      parse_args "$1" "$2"
      shift; 
      shift;
    fi
done

  log_info "install ALL"

  install_dependencies
  install_docker
  unregister_gitlab_runner

  cat /dev/null > ${CMDFILE}.tpl
  register_gitlab_runner
  register_gitlab_${EXECUTOR}
  register_gitlab_runner_tag
  register_gitlab_locked
  cp ${CMDFILE}.tpl ${CMDFILE}.sh
