provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  bucket_files = fileset("${path.module}/teams", "*/buckets/*.yaml")
  buckets = {
    for f in local.bucket_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/teams/${f}"))
  }
}

resource "google_storage_bucket" "team_buckets" {
  for_each = local.buckets

  name                        = each.value.name
  location                    = each.value.location
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_delete_days > 0 ? [1] : []
    content {
      condition {
        age = each.value.lifecycle_delete_days
      }
      action {
        type = "Delete"
      }
    }
  }

  labels = each.value.labels
}
