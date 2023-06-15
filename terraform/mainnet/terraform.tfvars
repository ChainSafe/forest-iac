# This is a set of values to be referenced as variables in the main code

size                    = "s-4vcpu-8gb"
image                   = "docker-20-04"
region                  = "fra1"
source_addresses        = ["0.0.0.0/0", "::/0"]
destination_addresses   = ["0.0.0.0/0", "::/0"]
initial_filesystem_type = "ext4"
chain                   = "mainnet"
project                 = "Forest-DEV"
volume_size             = "400"
volume_name             = "forest-mainnet-volume"
name                    = "forest"
fw_name                 = "forest-mainnet-fw"
# This set of variables are unique and must be defined here in order to deploy successfully
# digitalocean_token = ""
