#!/usr/bin/env bash

set -e

RESULT=0
COMPOSE_FILE="./tests/docker-compose.yml"
KEY_FILE="./tests/docker/ssh_key"
export ANSIBLE_SSH_RETRIES=5
export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_GATHER_SUBSET="network"

chmod 400 "${KEY_FILE}"

docker-compose -f "${COMPOSE_FILE}" kill
docker-compose -f "${COMPOSE_FILE}" down

docker-compose -f "${COMPOSE_FILE}" up --force-recreate -d
sleep 5
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" --limit "192.0.2.3,192.0.2.5" ./deploy.yml -e 'test=1'
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
sleep 5
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./deploy.yml -e 'test=1'
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
sleep 5
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_access.yml || RESULT=1
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
sleep 5
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_intrawire.yml || RESULT=1
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" start
sleep 5
ansible-playbook -i ./tests/hosts.yml --key-file "${KEY_FILE}" ./tests/check_extrawire.yml || RESULT=1
docker-compose -f "${COMPOSE_FILE}" kill

docker-compose -f "${COMPOSE_FILE}" down

exit ${RESULT}
