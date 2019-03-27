#!/usr/bin/env bash

set -e

COMPOSE_FILE="./tests/docker-compose.yml"
KEY_FILE="./tests/docker/ssh_key"
export ANSIBLE_SSH_RETRIES=5
export ANSIBLE_HOST_KEY_CHECKING="False"

docker-compose -f "${COMPOSE_FILE}" kill
docker-compose -f "${COMPOSE_FILE}" down

docker-compose -f "${COMPOSE_FILE}" up --force-recreate -d
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./deploy.yml -e 'test=1'
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_access.yml
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_intrawire.yml
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_extrawire.yml
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" down
