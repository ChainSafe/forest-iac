# This terraform script executes the following steps:
#  - Zip the ruby and shell script files (the hash of this zip file is used to
#    determine when to re-deploy the service)
#  - Boot a new droplet
#  - Copy over the zip file
#  - Run calibnet and mainnet sync check in the background

// Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_tar" {
  program = ["bash", "${path.module}/prep_sources.sh", path.module, var.common_resources_dir]
}

data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

data "digitalocean_ssh_keys" "keys" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = format("%s-%s", var.environment, var.name)
  region = var.region
  size   = var.size
  user_data = join("\n", [
    templatefile("${path.module}/service/user_data.yml.tpl", {
      FOREST_TARGET_DATA        = "/volumes/forest_data",
      FOREST_TARGET_SCRIPTS     = "/volumes/sync_check",
      FOREST_TARGET_RUBY_COMMON = "/volumes/ruby_common",
      slack_token               = var.slack_token,
      slack_channel             = var.slack_channel,
      NEW_RELIC_API_KEY         = var.new_relic_api_key,
      NEW_RELIC_ACCOUNT_ID      = var.new_relic_account_id,
      NEW_RELIC_REGION          = var.new_relic_region,
      forest_tag                = "edge-fat"
    }),
    "# sources sha256: ${data.local_file.sources.content_sha256}",
  ])

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
