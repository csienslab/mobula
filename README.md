# Mobula
Mobula: Mesh Obfuscated Local Network

## Terminology
- Deployer: The computer which runs this script to deploy Mobula network on hosts
  - It is usually your personal computer
- Host: The computer which will run with Mobula network
  - They are usually your servers

## Prerequisite
### On Deployer
- git
- virtualenv

### On Hosts
- Python 2 or 3 (`/usr/bin/python` must be in `${PATH}`)
- Make sure deployer can ssh in as the `root` user

## Install
### On Deployer
Get Mobula and change the current working directory
```sh
git clone ${mobula repository}
cd mobula
```
Initialize the python environment
```sh
virtualenv -p=python3 .env
. .env/bin/activate
pip install -r requirements.txt
```

## Configuration
There are 3 config files must be created and configured before deploying:
- hosts.yml
- extra_hosts.yml
- extra_wires.yml

## Deploy
### On Deployer
```sh
ansible-playbook -i hosts.yml ./deploy.yml
```
