![Imgur](https://imgur.com/iWrzKv7.png)

## Terminology
- Deployer: The computer which runs this script to deploy Mobula network on hosts
  - It is usually your personal computer
- Host: The computer which will run with Mobula network
  - They are usually your servers
- Access Network: The layer 2 virtual network provided by Mobula
- WireGuard Network: The fully connected peer-to-peer network between hosts over WireGuard
- Extrawire Network: The network for external WireGuard clients which can connect to access network
- Local DNS Server: The DNS server maintained by Mobula to resolve private FQDNs in access network

## Prerequisite
### On Deployer
- git
- virtualenv
- wireguard

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

## The Mobula Network Design
In order to understand how to configure Mobula, you need to know the design of Mobula network. Here, given the `${Host ID}` of a host, we define `x.z` of the host as `${Host ID / 256}.${Host ID % 256}` and `y.z` as `${Host ID / 256 + 128}.${Host ID % 256}`

There are 3 virtual networks in Mobula:
- Access network
- WireGuard network
- Extrawire network

Each host will have 3 virtual interfaces:
- `veth_fac0`
  - Can reach access network
  - Assigned IP: `10.31.z.y/16`
  - Reachable subnet: `10.31.0.0/16`
- `mo-dir-hs`
  - Can reach WireGuard network and Extrawire network
  - Assigned IP: `10.30.x.y/32`
  - Reachable subnet: `10.30.0.0/16`
- `veth_${host external interface}`
  - Host's orignal external interface

### Topology
Suppose there are 3 hosts: Host 1, Host 2, and Host 3. The gateways of Host 1 and Host 2 are not drawn on the topology, but they are similar to the gateway of Host 3
```
+-------------------------------------------------------------------+
|                                                                   |
| Public, External Network <-----+         +----------------------+ |
|                                |         |                      | |
| +-------------------+          |         |   +---------------+  | |
| |                   |          |         |   |Host ID 3      |  | |
| |  Your SSH Client  +----------+         |   |               |  | |
| |                   |          |         |   | +-----------+ |  | |
| +-------------------+          +---------------> Gateway   | |  | |
|                                          |   | | 10.31.0.3 | |  | |
| +----------------------------------------+   | |           | |  | |
| |Access Network 10.31.0.0/16                 | | Firewall  | |  | |
| |                                            | | Dnsmasq   | |  | |
| |              ^                    ^        | | WireGuard | |  | |
| |              |                    |        | |           | |  | |
| |  +---------------+    +---------------+    | +-----^-----+ |  | |
| |  |Host ID 1  |   |    |Host ID 2  |   |    |       |       |  | |
| |  |           |   |    |           |   |    |       |       |  | |
| |  | +---------+-+ |    | +---------+-+ |    | +-----v-----+ |  | |
| |  | |           | |    | |           | |    | |           | |  | |
| |  | | veth_fac0 | |    | | veth_fac0 | |  <---+ veth_fac0 | |  | |
| |  | |10.31.128.1| |    | |10.31.128.2| |    | |10.31.128.3| |  | |
| |  | +-----------+ |    | +-----------+ |    | +-----------+ |  | |
| |  |               |    |               |    |               |  | |
| +---------------------------------------------------------------+ |
| |  |               |    |               |    |               |  | |
| |  | +-----------+ |    | +-----------+ |    | +-----------+ |  | |
| |  | |           | |    | |           | |    | |           | |  | |
| |  | | mo-dir-hs <--------> mo-dir-hs <--------> mo-dir-hs | |  | |
| |  | | 10.30.0.1 | |    | | 10.30.0.2 | |    | | 10.30.0.3 | |  | |
| |  | +-----^-----+ |    | +-----------+ |    | +-----^--^--+ |  | |
| |  |       |       |    |               |    |       |  |    |  | |
| |  +---------------+    +---------------+    +---------------+  | |
| |          |                                         |  |       | |
| |          +-----------------------------------------+  |       | |
| |                                                       |       | |
| |                                       +-----------------------+ |
| |                                       |               |         |
| |                                       |    +----------+-------+ |
| |WireGuard Network 10.30.0.0/17         |    | Extrawire Client | |
| |Extrawire Network 10.30.128.0/17       |    |  10.30.128.1/32  | |
| +---------------------------------------+    +------------------+ |
|                                                                   |
+-------------------------------------------------------------------+
```

### Access network
The main layer 2 virtual network. ARP and VLAN work in this network. Each host also has a gateway on `10.31.x.y`, which provide the external network access and the DNS resolution(by local DNS server). For example, you should set `10.31.x.y` as the default gateway on a host so as to reach the external Internet

Except for the host's IP addresses `10.31.x.y` and `10.31.z.y`, any other IP addresses in `10.31.0.0/16` can be used on access network. For example, you can bridge your VM network to `veth_fac0` and assign an unused IP `10.31.?.?/16`, then your VM can access all hosts and their gateways

### WireGuard network
WIP

### Extrawire network
WIP

## Configuration
There are 3 config files must be created and configured before deploying:
- hosts.yml
- extra_hosts.yml
- extra_wires.yml

### hosts.yml
This file describes the hosts and the settings of access network. Because it also contains the private keys of WireGuard, this file should be protected. Example can be found at `hosts.yml.example`
```yml
all:
  hosts:
    ${Host external IP, which can access Internet}:
      host_id: ${Host ID, which must be in the range [1, 32767]}
      hostname: '${Host FQDN in access network, which can be a private domain}'
      wireguard:
        public_key: '${Unique WireGuard public key}'
        private_key: '${Unique WireGuard private key}'
```
You can generate the WireGuard key pair of each host by using the following commands:
```sh
wg genkey | tee privatekey | wg pubkey > publickey
cat publickey
cat privatekey
```

### extra_hosts.yml
This file describes the extra FQDNs in access network, which should be registered to local DNS servers. Example can be found at `extra_hosts.yml.example`
```yml
extra_hosts:
  ${access network IP 1}: '${FQDN 1}'
  ${access network IP 2}: '${FQDN 2}'
```

### extra_wires.yml
The file describes the external WireGuard clients which can connect to access network. Example can be found at `extra_wires.yml.example`
```yml
extra_wires:
  ${extrawire IP 1, which must be in the subnet 10.30.128.0/17}/32: 'WireGuard public key 1'
```

## Deploy
### On Deployer
#### Normal Deploying
It will install Mobula on the new hosts and update configuration on existed hosts. During installation, the new hosts will be rebooted
```sh
ansible-playbook -i hosts.yml ./deploy.yml
```

#### Force Deploying
Reinstall Mobula and reboot all hosts
```sh
ansible-playbook -i hosts.yml ./deploy.yml -e 'reinstall=1'
```

Note: Every time you change the configuration or add/remove hosts, you can directly rerun the deploying commands to update your Mobula network

### On Host
After installation, `veth_fac0` won't be assigned any IP address, you should set the IP `10.31.z.y/16` on it and add the default gateway `10.31.x.y` with the network configuration tool on your host.
