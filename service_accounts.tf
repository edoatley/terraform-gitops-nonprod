# Service Accounts (ADR-010): one keyless google_service_account per
# teams/{team}/service-accounts/{name}.yaml, plus one google_project_iam_member per role.
# No google_service_account_key is ever created. SAs cannot carry labels, so the governance
# labels are written into the description as an ownership marker that FastAPI's CAI discovery
# parses (ADR-010 Q10.3).

locals {
  service_account_files = fileset("${path.module}/teams", "*/service-accounts/*.yaml")
  service_accounts = {
    for f in local.service_account_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/teams/${f}"))
  }

  service_account_descriptions = {
    for k, sa in local.service_accounts :
    k => trimspace("[managed_by=terraform team=${sa.labels.team} owner=${sa.labels.owner}] ${try(sa.description, "")}")
  }

  service_account_roles = merge([
    for k, sa in local.service_accounts : {
      for role in sa.roles : "${k}/${role}" => { service_account = k, role = role }
    }
  ]...)

  # Defence in depth: FastAPI rejects these, but YAML can also arrive by a hand-written MR.
  primitive_roles = ["roles/owner", "roles/editor", "roles/viewer"]
}

resource "google_service_account" "team_service_accounts" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.value.name
  display_name = try(each.value.display_name, each.value.name)
  description  = local.service_account_descriptions[each.key]

  lifecycle {
    precondition {
      condition     = can(regex("^jlp-${each.value.labels.team}-[a-z0-9-]*[a-z0-9]$", each.value.name)) && length(each.value.name) <= 30
      error_message = "Service account '${each.value.name}' must be jlp-{team}-{name}, at most 30 characters (ADR-010)."
    }
    precondition {
      condition     = try(each.value.credential_mode, "keyless") == "keyless"
      error_message = "Service account '${each.value.name}': only credential_mode = keyless is supported (ADR-010 Q10.1)."
    }
    precondition {
      condition     = length(local.service_account_descriptions[each.key]) <= 256
      error_message = "Service account '${each.value.name}': description plus ownership marker exceeds 256 characters."
    }
  }
}

resource "google_project_iam_member" "team_service_account_roles" {
  for_each = local.service_account_roles

  project = var.project_id
  role    = each.value.role
  member  = google_service_account.team_service_accounts[each.value.service_account].member

  lifecycle {
    precondition {
      condition     = !contains(local.primitive_roles, each.value.role)
      error_message = "Primitive role ${each.value.role} is never granted to a service account (ADR-010)."
    }
  }
}
