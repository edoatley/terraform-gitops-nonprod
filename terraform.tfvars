# Written by cloud-resource-lifecycle scripts/gitops-repo-assemble.sh
project_id = "gcp-sandbox-2026-18798"
region     = "europe-west2"

# The project has no GCP organization, so the pipeline can't create sandbox projects
# (Day 1 plan, decision D2). Sandbox YAML still merges; nothing is created.
enable_sandbox_projects = false
