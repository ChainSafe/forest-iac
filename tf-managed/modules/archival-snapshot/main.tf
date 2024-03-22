# This terraform script executes the following steps:
#  - Sync with latest lite+diff snapshots.
#  - Export a large master snapshot covering, say, 30,000 epochs.
#  - Generate diffs and lite snapshots from the master snapshot. Eg. forest-tool archive export ...
#  - Upload generated snapshots.

# Ugly hack because 'archive_file' cannot mix files and folders.
data "external" "sources_tar" {
  program = ["bash", "${path.module}/prep_sources.sh", path.module]
}

data "local_file" "sources" {
  filename = data.external.sources_tar.result.path
}

data "local_file" "init" {
  filename = "${path.module}/service/init.sh"
}

# Required environment variables for the service.
locals {
  env_content = <<-EOT
    SLACK_TOKEN=${var.slack_token}
    SLACK_CHANNEL=${var.slack_channel}
  EOT
}

resource "null_resource" "copy_and_execute" {
  depends_on = [data.external.sources_tar]

  provisioner "file" {
    source      = data.local_file.sources.filename
    destination = "/tmp/sources.tar"

    connection {
      type        = "ssh"
      host        = "archie.chainsafe.dev"
      user        = "archie"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /mnt/md0/exported/archival",
      "mv /tmp/sources.tar /mnt/md0/exported/archival/sources.tar",
      "cd /mnt/md0/exported/archival",
      "tar xf sources.tar",
      "nohup sh ./init.sh > ./init_log.txt &",
      "sleep 60s",
    ]

    connection {
      type        = "ssh"
      host        = "archie.chainsafe.dev"
      user        = "archie"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}
