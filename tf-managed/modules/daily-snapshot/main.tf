# This terraform script executes the following steps:
#  - Zip the ruby and shell script files (the hash of this zip file is used to
#    determine when to re-deploy the service)
#  - Boot a new droplet
#  - Copy over the zip file
#  - Run the init.sh script in the background

// Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_tar" {
  program = ["bash", "${path.module}/prep_sources.sh", path.module]
}


data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

// Note: The init.sh file is also included in the sources.zip such that the hash
// of the archive captures the entire state of the machine.
// This is a workaround, and because of this, we need to suppress the tflint warning here
// for unused declarations related to the 'init.sh' file. tflint-ignore: terraform_unused_declarations
data "local_file" "init" {
  filename = "${path.module}/service/init.sh"
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

# Required environment variables for the snapshot service itself.
locals {
  env_content = <<-EOT
  R2_ACCESS_KEY=${var.R2_ACCESS_KEY}
  R2_SECRET_KEY=${var.R2_SECRET_KEY}
  R2_ENDPOINT=${var.r2_endpoint}
  SNAPSHOT_BUCKET=${var.snapshot_bucket}
  SLACK_API_TOKEN=${var.slack_token}
  SLACK_NOTIFICATION_CHANNEL=${var.slack_channel}
  FOREST_TAG=${var.forest_tag}
  EOT
}

locals {
  init_commands = ["cd /root/",
    "tar xf sources.tar",
    "echo '${local.env_content}' >> /root/.forest_env",
    <<-EOT
    export NEW_RELIC_API_KEY=${var.new_relic_api_key}
    export NEW_RELIC_ACCOUNT_ID=${var.new_relic_account_id}
    export NEW_RELIC_REGION=${var.new_relic_region}
    nohup sh ./init.sh > init_log.txt &
    EOT
    ,
    # Exiting without a sleep sometimes kills the script :-/
    "sleep 60s"
  ]

  service_name = format("%s-%s", var.environment, var.name)
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = local.service_name
  region = var.region
  size   = var.size
  # Re-initialize resource if this hash changes:
  user_data  = join("-", [data.local_file.sources.content_sha256, sha256(join("", local.init_commands))])
  tags       = ["iac", var.environment]
  ssh_keys   = data.digitalocean_ssh_keys.keys.ssh_keys[*].fingerprint
  monitoring = true

  graceful_shutdown = false

  connection {
    host    = self.ipv4_address
    user    = "root"
    type    = "ssh"
    timeout = "30m"
  }

  # Push the sources.tar file to the newly booted droplet
  provisioner "file" {
    source      = data.local_file.sources.filename
    destination = "/root/sources.tar"
  }

  provisioner "remote-exec" {
    inline = local.init_commands
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

module "monitoring" {
  count                = var.monitoring.enable ? 1 : 0
  source               = "./monitoring"
  service_name         = local.service_name
  alert_email          = var.monitoring.alert_email
  slack_enable         = var.monitoring.slack_enable
  slack_destination_id = var.monitoring.slack_destination_id
  slack_channel_id     = var.monitoring.slack_channel_id
}
