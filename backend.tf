# Remote state in GCS — create this bucket manually first (chicken-and-egg).
# Run once:
#   gsutil mb -l us-central1 gs://time-series-quant-tfstate
#   gsutil versioning set on gs://time-series-quant-tfstate

terraform {
  backend "gcs" {
    bucket = "time-series-quant-tfstate" # replace with your actual bucket
    prefix = "gdp-forecast"
  }
}
