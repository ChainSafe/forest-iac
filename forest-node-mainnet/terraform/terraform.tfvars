# This is a set of values to be referenced as variables in the main code

size                    = "c2-8vcpu-16gb"
image                   = "docker-20-04"
region                  = "fra1"
source_addresses        = ["0.0.0.0/0", "::/0"]
destination_addresses   = ["0.0.0.0/0", "::/0"]
backups                 = "false"
volume_size             = "1000"
protocol                = "tcp"
initial_filesystem_type = "ext4"

# This set of variables are unique and must be defined here in order to deploy successfully
name                        = ""
new_key_ssh_key_fingerprint = ""
digitalocean_token          = ""
observability_name          = ""