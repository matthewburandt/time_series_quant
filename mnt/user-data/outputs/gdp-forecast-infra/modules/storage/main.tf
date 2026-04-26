variable "project_id" { type = string }
variable "region" { type = string }
variable "prefix" { type = string }
variable "labels" { type = map(string) }
variable "environment" { type = string }

resource "google_storage_bucket" "raw_data" {
  name     = "${var.prefix}-raw-${var.project_id}"
  project  = var.project_id
  location = var.region
  labels   = var.labels

  # Prevent accidental deletion in prod
  force_destroy = var.environment == "dev" ? true : false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90 # clean up old versions after 90 days
    }
    action {
      type = "Delete"
    }
  }
}

output "raw_bucket_name" {
  value = google_storage_bucket.raw_data.name
}

output "raw_bucket_url" {
  value = google_storage_bucket.raw_data.url
}
