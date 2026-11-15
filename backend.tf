# State lives in the bucket made by cloud-resource-lifecycle's infra-gitops-pipeline. The bucket
# name is passed at init (-backend-config="bucket=..."), from the TF_STATE_BUCKET repo variable.
terraform {
  backend "gcs" {
    prefix = "gitops"
  }
}
