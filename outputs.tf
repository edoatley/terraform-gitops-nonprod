output "provisioned_buckets" {
  description = "Map of provisioned team GCS buckets from YAML definitions"
  value = {
    for k, b in google_storage_bucket.team_buckets : k => {
      name          = b.name
      url           = b.url
      location      = b.location
      storage_class = b.storage_class
      labels        = b.labels
    }
  }
}

output "provisioned_sandboxes" {
  description = "Map of provisioned team project sandboxes from YAML definitions"
  value = {
    for k, p in google_project.team_sandboxes : k => {
      project_id = p.project_id
      number     = p.number
      expires_on = try(p.labels.expires_on, null)
      labels     = p.labels
    }
  }
}

output "provisioned_service_accounts" {
  description = "Map of provisioned keyless team service accounts and their project roles"
  value = {
    for k, sa in google_service_account.team_service_accounts : k => {
      email = sa.email
      roles = sort([for r in local.service_account_roles : r.role if r.service_account == k])
    }
  }
}
