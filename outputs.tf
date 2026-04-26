output "raw_bucket_name" {
  description = "GCS bucket for raw FRED data"
  value       = module.storage.raw_bucket_name
}

output "raw_bucket_url" {
  description = "GCS bucket URL"
  value       = module.storage.raw_bucket_url
}

output "bq_dataset_id" {
  description = "BigQuery dataset for dbt transformations"
  value       = module.bigquery.dataset_id
}

output "pipeline_sa_email" {
  description = "Service account email for Kestra/dbt to authenticate"
  value       = module.iam.pipeline_sa_email
}

output "pipeline_sa_key_instructions" {
  description = "How to generate a key for the pipeline SA"
  value       = "Run: gcloud iam service-accounts keys create key.json --iam-account=${module.iam.pipeline_sa_email}"
}
