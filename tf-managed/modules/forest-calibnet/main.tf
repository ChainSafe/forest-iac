# This terraform script executes the following steps:
#  - Zip the ruby and shell script files (the hash of this zip file is used to
#    determine when to re-deploy the service)
#  - Boot a new droplet
#  - Copy over the zip file
#  - Run the init.sh script in the background

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

locals {
  service_name = format("%s-%s", var.environment, var.name)
}

resource "digitalocean_droplet" "forest" {
  image      = var.image
  name       = local.service_name
  region     = var.region
  size       = var.size
  tags       = ["iac", var.environment]
  ssh_keys   = data.digitalocean_ssh_keys.keys.ssh_keys[*].fingerprint
  monitoring = true

  graceful_shutdown = false

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/bootstrap.bash.tftpl",
      {
        NEW_USER             = var.forest_user
        CHAIN                = var.chain
        NR_LICENSE_KEY       = "" // var.NR_LICENSE_KEY
        NEW_RELIC_API_KEY    = "" // var.NEW_RELIC_API_KEY
        NEW_RELIC_ACCOUNT_ID = "" // var.NEW_RELIC_ACCOUNT_ID
        NEW_RELIC_REGION     = "" // var.NEW_RELIC_REGION
    })
    destination = "/root/bootstrap.bash"
  }

  provisioner "remote-exec" {
    inline = [
      "script /root/bootstrap.log --command 'bash /root/bootstrap.bash'"
    ]
  }
}


data "digitalocean_project" "forest_project" {
  name = var.project
}

# Connect the droplet to the forest project (otherwise it ends up in
# "ChainBridge" which is the default project)
resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}
