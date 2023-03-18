# This is a set of values to be referenced as variables in the main code

size = "c2-16vcpu-32gb"
image = "protocollabs-filecoinlotus-20-04"
region = "fra1"
source_addresses = ["0.0.0.0/0", "::/0"]
destination_addresses = ["0.0.0.0/0", "::/0"]
backups = "false"

# This set of variables are unique and must be defined here in order to deploy successfully
name = ""
new_key_ssh_key_fingerprint = ""
digitalocean_token = ""
hubert_key_ssh_key_fingerprint = ""
guillame_key_ssh_key_fingerprint = ""
david_key_ssh_key_fingerprint = ""
