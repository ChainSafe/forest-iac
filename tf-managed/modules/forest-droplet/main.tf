locals {
  droplet_name = format("%s-%s", var.environment, var.service_name)
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

// This needs to be its own resource so that terraform recreates the droplet when it changes
resource "local_sensitive_file" "bootstrap_script" {
  filename = "bootstrap.bash"
  content = templatefile(
    "${path.module}/bootstrap.bash.tftpl",
    {
      NEW_USER             = "user" // TODO(aatifsyed): refactor bootstrap script to not require this
      CHAIN                = var.chain
      NR_LICENSE_KEY       = "" // var.NR_LICENSE_KEY // TODO(aatifsyed): plug this functionality
      NEW_RELIC_API_KEY    = var.new_relic_api_key != null ? var.new_relic_api_key : ""
      NEW_RELIC_ACCOUNT_ID = var.new_relic_account_id != null ? var.new_relic_account_id : ""
      NEW_RELIC_REGION     = "EU"
      FOREST_TAG           = var.forest_tag
    }
  )
}

resource "digitalocean_droplet" "forest" {
  image      = "docker-20-04" // https://marketplace.digitalocean.com/apps/docker
  name       = local.droplet_name
  region     = "fra1"
  size       = var.droplet_size
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
    content     = local_sensitive_file.bootstrap_script.content
    destination = "/root/bootstrap.bash"
  }

  provisioner "remote-exec" {
    inline = [
      "script /root/bootstrap.log --command 'bash /root/bootstrap.bash'"
    ]
  }

  lifecycle {
    replace_triggered_by = [local_sensitive_file.bootstrap_script]
    create_before_destroy = true
  }
}

data "digitalocean_project" "forest_project" {
  name = "Forest-DEV"
}

# Assign the droplet out of the default project
resource "digitalocean_project_resources" "connect_forest_project" {
  project   = data.digitalocean_project.forest_project.id
  resources = [digitalocean_droplet.forest.urn]
}
