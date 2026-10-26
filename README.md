# terraform-gitops-nonprod

Non-prod GitOps target for the Cloud Enablement FastAPI GitOps Engine (Workstream A smoke test).

The engine opens pull requests that add, update or remove partitioned YAML files at
`teams/{team}/{resource_type}/{name}.yaml`. Policy exceptions get a `Draft:` title and a linked
`CLD-*` ticket in the Jira Sandbox.

Source: https://github.com/edoatley/cloud-resource-lifecycle
