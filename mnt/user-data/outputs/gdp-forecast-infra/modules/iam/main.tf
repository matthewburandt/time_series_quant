variable "project_id" { type = string }
variable "prefix" { type = string }
variable "raw_bucket_name" { type = string }
variable "bq_dataset_id" { type = string }

# ---- Pipeline service account ----
# Used by Kestra and dbt to authenticate against GCP.
resource "google_service_account" "pipeline" {
  account_id   = "${var.prefix}-pipeline"
  display_name = "GDP Forecast Pipeline SA"
  description  = "Used by Kestra (orchestrator) and dbt (transforms)"
  project      = var.project_id
}

# ---- GCS permissions: read/write raw data ----
resource "google_storage_bucket_iam_member" "pipeline_gcs_writer" {
  bucket = var.raw_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# ---- BigQuery permissions: read/write dataset ----
resource "google_bigquery_dataset_iam_member" "pipeline_bq_editor" {
  dataset_id = var.bq_dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.pipeline.email}"
}

# dbt and Kestra also need to run BQ jobs
resource "google_project_iam_member" "pipeline_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}

output "pipeline_sa_email" {
  value = google_service_account.pipeline.email
}
