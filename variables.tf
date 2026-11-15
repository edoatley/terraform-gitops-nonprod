variable "project_id" {
  description = "GCP Project ID where team GCS buckets are provisioned"
  type        = string
  default     = "jlp-cloud-enablement-poc"
}

variable "region" {
  description = "Default GCP region for provider operations"
  type        = string
  default     = "europe-west2"
}

variable "sandbox_folder_id" {
  description = "Folder for team project sandboxes (ADR-009 §5). Null creates them without a folder parent, e.g. in standalone non-prod."
  type        = string
  default     = null
}

variable "enable_sandbox_projects" {
  description = "Create GCP projects for teams/*/sandboxes/*.yaml. Set false where the pipeline can't create projects, e.g. a project with no organization (Day 1 plan, decision D2): sandbox YAML is still merged, but nothing is created."
  type        = bool
  default     = true
}

variable "billing_account_id" {
  description = "Billing account linked to sandboxes. Null skips the billing link and budget alerts, so validate/plan works offline."
  type        = string
  default     = null
}

variable "budget_currency_code" {
  description = "Currency of the sandbox budgets; must match the billing account's currency."
  type        = string
  default     = "GBP"
}
