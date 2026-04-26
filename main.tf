# =============================================================================
# GDP Forecast Pipeline — Infrastructure
# =============================================================================
# Architecture:
#   FRED API → (Kestra) → GCS (raw) → BigQuery (dbt transforms) → Looker Studio
#
# Kestra runs externally (self-hosted or Kestra Cloud). This config provisions
# the GCP resources it interacts with: buckets, datasets, service accounts, IAM.
# =============================================================================

locals {
  prefix = "gdp-forecast"
  labels = {
    project     = "gdp-forecast"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ---- Storage: raw data landing zone ----
module "storage" {
  source      = "./modules/storage"
  project_id  = var.project_id
  region      = var.region
  prefix      = local.prefix
  labels      = local.labels
  environment = var.environment
}

# ---- BigQuery: transformation & analytics layer ----
module "bigquery" {
  source      = "./modules/bigquery"
  project_id  = var.project_id
  region      = var.region
  prefix      = local.prefix
  labels      = local.labels
  environment = var.environment
}

# ---- IAM: service accounts & permissions ----
module "iam" {
  source             = "./modules/iam"
  project_id         = var.project_id
  prefix             = local.prefix
  raw_bucket_name    = module.storage.raw_bucket_name
  bq_dataset_id      = module.bigquery.dataset_id
}

# ---- Secret Manager: FRED API key ----
resource "google_secret_manager_secret" "fred_api_key" {
  secret_id = "${local.prefix}-fred-api-key"
  project   = var.project_id

  labels = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "fred_api_key" {
  secret      = google_secret_manager_secret.fred_api_key.id
  secret_data = var.fred_api_key
}

# Grant the pipeline SA access to read the secret
resource "google_secret_manager_secret_iam_member" "pipeline_sa_secret_access" {
  secret_id = google_secret_manager_secret.fred_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.iam.pipeline_sa_email}"
}
