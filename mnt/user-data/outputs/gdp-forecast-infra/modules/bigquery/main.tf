variable "project_id" { type = string }
variable "region" { type = string }
variable "prefix" { type = string }
variable "labels" { type = map(string) }
variable "environment" { type = string }

# ---- Dataset: dbt writes transformed tables here ----
resource "google_bigquery_dataset" "gdp_forecast" {
  dataset_id    = replace("${var.prefix}_${var.environment}", "-", "_")
  project       = var.project_id
  location      = var.region
  friendly_name = "GDP Forecast Pipeline (${var.environment})"
  description   = "Real GDP time series — raw ingestion, dbt transforms, ARMA model inputs"
  labels        = var.labels

  # 90-day default expiration for dev tables; remove for prod
  default_table_expiration_ms = var.environment == "dev" ? 7776000000 : null

  delete_contents_on_destroy = var.environment == "dev" ? true : false
}

# ---- Raw landing table: FRED GDP series ----
# dbt will read from this and build staging/mart layers on top.
resource "google_bigquery_table" "raw_gdp" {
  dataset_id = google_bigquery_dataset.gdp_forecast.dataset_id
  table_id   = "raw_real_gdp"
  project    = var.project_id
  labels     = var.labels

  description = "Raw real GDP data from FRED (series GDPC1). Loaded by Kestra."

  schema = jsonencode([
    {
      name = "observation_date"
      type = "DATE"
      mode = "REQUIRED"
      description = "Quarter start date"
    },
    {
      name = "real_gdp"
      type = "FLOAT64"
      mode = "REQUIRED"
      description = "Real GDP in billions of chained 2017 dollars"
    },
    {
      name = "ingested_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
      description = "When this row was loaded into BQ"
    },
    {
      name = "source_file"
      type = "STRING"
      mode = "NULLABLE"
      description = "GCS path of the source file"
    }
  ])
}

output "dataset_id" {
  value = google_bigquery_dataset.gdp_forecast.dataset_id
}

output "raw_table_id" {
  value = google_bigquery_table.raw_gdp.table_id
}
