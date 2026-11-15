# Project Sandboxes (ADR-009): one google_project per teams/{team}/sandboxes/{name}.yaml.
# FastAPI's teardown/reaper MRs delete the YAML; deletion_policy = "DELETE" then places the
# project in GCP's native 30-day DELETE_REQUESTED recovery window.

locals {
  sandbox_files = fileset("${path.module}/teams", "*/sandboxes/*.yaml")
  sandboxes = {
    for f in local.sandbox_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/teams/${f}"))
  }

  # GCP project IDs and display names are capped at 30 characters (ADR-009 §5), so longer
  # jlp-{team}-sbx-{name} names are truncated unless the YAML pins an explicit project_id.
  # Day 1 plan D2: without an organization the pipeline can't create projects, so sandboxes can be
  # switched off while the API, Jira routing and teardown PRs keep working on the YAML.
  sandbox_projects = var.enable_sandbox_projects ? local.sandboxes : {}

  sandbox_project_ids = {
    for k, s in local.sandboxes :
    k => try(s.project_id, trimsuffix(substr(s.name, 0, 30), "-"))
  }
}

resource "google_project" "team_sandboxes" {
  for_each = local.sandbox_projects

  name            = local.sandbox_project_ids[each.key]
  project_id      = local.sandbox_project_ids[each.key]
  folder_id       = var.sandbox_folder_id
  billing_account = var.billing_account_id
  deletion_policy = "DELETE"

  labels = each.value.labels

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", local.sandbox_project_ids[each.key]))
      error_message = "Derived project_id '${local.sandbox_project_ids[each.key]}' is not a valid GCP project ID; set project_id in the sandbox YAML."
    }
    precondition {
      condition     = length(distinct(values(local.sandbox_project_ids))) == length(local.sandbox_project_ids)
      error_message = "Two sandboxes truncate to the same 30-character project_id; set project_id in one of the sandbox YAMLs."
    }
  }
}

resource "google_billing_budget" "sandbox_budgets" {
  for_each = var.billing_account_id == null ? {} : local.sandbox_projects

  billing_account = var.billing_account_id
  display_name    = "sandbox-${local.sandbox_project_ids[each.key]}"

  budget_filter {
    projects = ["projects/${google_project.team_sandboxes[each.key].number}"]
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency_code
      units         = tostring(try(each.value.budget_limit_gbp, 500))
    }
  }

  # ADR-009 §3: 50% / 90% / 100% alerts to the owning squad and FinOps.
  dynamic "threshold_rules" {
    for_each = [0.5, 0.9, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }
}
