# This is a set of values to be referenced as variables in the main code

size = "s-4vcpu-8gb"
image = "docker-20-04"
region = "fra1"
source_addresses = ["0.0.0.0/0", "::/0"]
destination_addresses = ["0.0.0.0/0", "::/0"]
backups = "false"

# This set of variables are unique and must be defined here in order to deploy successfully
name = ""
new_key_ssh_key_fingerprint = "" 
firewall_name = ""
