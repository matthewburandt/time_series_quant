# GDP Forecast Pipeline — Infrastructure

Terraform config for a real GDP forecasting pipeline using ARMA models.

## Architecture

```
FRED API
  │
  ▼
┌──────────┐     ┌─────────────────┐     ┌──────────────┐     ┌───────────────┐
│  Kestra  │───▶│  GCS Bucket     │────▶│  BigQuery    │───▶│ Looker Studio │
│  (orch)  │     │  (raw JSON/CSV) │     │  (dbt models)│     │  (dashboards) │
└──────────┘     └─────────────────┘     └──────────────┘     └───────────────┘
```

**FRED → Kestra:** Pulls real GDP (series GDPC1) via FRED API, writes to GCS.
**GCS → BigQuery:** Kestra loads raw data into `raw_real_gdp` table.
**dbt:** Builds staging and mart layers — lag features, ACF inputs, ARMA model features.
**Looker Studio:** Connects to BigQuery for time series plots, scatter plots, ACF charts.

## What Terraform manages

| Resource               | Purpose                                      |
|------------------------|----------------------------------------------|
| GCS bucket             | Raw data landing zone                        |
| BigQuery dataset       | All tables (raw + dbt-managed)               |
| BigQuery table         | `raw_real_gdp` schema                        |
| Service account        | Pipeline identity (Kestra + dbt)             |
| IAM bindings           | Least-privilege access to GCS, BQ, Secrets   |
| Secret Manager secret  | FRED API key                                 |

## What Terraform does NOT manage

- **Kestra** — self-hosted or Kestra Cloud, configured separately
- **dbt** — runs in VS Code via `dbt run`, uses the SA key for auth
- **Looker Studio** — connected manually to BigQuery dataset

## Setup

### Prerequisites
- [Terraform >= 1.5](https://developer.hashicorp.com/terraform/downloads)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated
- A GCP project with billing enabled
- APIs enabled: BigQuery, Cloud Storage, Secret Manager, IAM

```bash
# Enable required APIs
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com
```

### Deploy

```bash
# 1. Create the tfstate bucket (one-time, manual)
gsutil mb -l us-central1 gs://YOUR_PROJECT_ID-tfstate
gsutil versioning set on gs://YOUR_PROJECT_ID-tfstate

# 2. Update backend.tf and terraform.tfvars with your project ID

# 3. Init, plan, apply
terraform init
terraform plan    # review carefully
terraform apply   # type 'yes' to confirm

# 4. Generate SA key for Kestra/dbt
terraform output pipeline_sa_key_instructions
# Then run the printed gcloud command
```

### Connecting dbt

```bash
# In your dbt project's profiles.yml:
gdp_forecast:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: YOUR_PROJECT_ID
      dataset: gdp_forecast_dev
      keyfile: /path/to/key.json
      threads: 4
      location: us-central1
```

## dbt model roadmap (not Terraform-managed)

These are the models you'd build in dbt on top of `raw_real_gdp`:

| Model                    | Layer   | Purpose                                        |
|-------------------------|---------|-------------------------------------------------|
| `stg_real_gdp`          | staging | Clean, typed, deduped                           |
| `int_gdp_lags`          | intermediate | GDP at t-1, t-2, ... t-k for regression inputs |
| `int_gdp_log_returns`   | intermediate | ln(GDP_t / GDP_{t-1}) for stationarity         |
| `int_gdp_acf`           | intermediate | Autocorrelation at lags 1..20                  |
| `mart_arma_features`    | mart    | Final feature set for ARMA(p,q) modeling        |
| `mart_forecast_results` | mart    | Model predictions vs actuals                    |
