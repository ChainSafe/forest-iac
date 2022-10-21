# Sync check setup
## Prerequisites
* Linux server with decent specs and docker. Battle-tested on:
```
Fedora Linux 36 (Cloud Edition) x86_64
8 vCPUs
16GB / 320GB Disk
```
* Slack OAuth token (you can find it in the Slack app settings) needs to be set as an environmental variable, along with the target slack channel. See [.env](.env) for naming.

## Installation
* ensure all environmental variables are set,
* run `./boot_service.sh`
