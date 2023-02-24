terraform {
  required_version = "~> 1.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_droplet" "forest" {
  image  = var.image
  name   = var.name
  region = var.region
  size   = var.size
  backups = var.backups
  ssh_keys = [var.new_key_ssh_key_fingerprint]

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_droplet" "forest-observability" {
  image    = var.image
  name     = var.observability_name
  region   = var.region
  size     = var.size
  backups  = var.backups
  ssh_keys = [var.new_key_ssh_key_fingerprint]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_spaces_bucket" "observability" {
  name   = var.spaces_name
  region = "nyc3"
}

resource "digitalocean_spaces_bucket_policy" "observability_policy" {
  region = digitalocean_spaces_bucket.observability.region
  bucket = digitalocean_spaces_bucket.observability.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "IPAllow",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${digitalocean_spaces_bucket.observability.name}",
          "arn:aws:s3:::${digitalocean_spaces_bucket.observability.name}/*"
        ],
        "Condition" : {
          "NotIpAddress" : {
            "aws:SourceIp" : [
              "${digitalocean_droplet.forest-observability.ipv4_address}/32"
            ]
          }
        }
      }
    ]
  })
}

output "ip" {
  value = [digitalocean_droplet.forest.ipv4_address, digitalocean_droplet.spaces.ipv4_address, digitalocean_droplet.observaility.ipv4_address]
}

resource "local_file" "hosts" {
  content = templatefile("../ansible/hosts",
    {
      forest        = digitalocean_droplet.forest.ipv4_address.*
      observability = digitalocean_droplet.forest-observability.ipv4_address.*
      spaces        = digitalocean_spaces_bucket.observability.name.*
    }
  )
  filename = "../ansible/hosts"
}
