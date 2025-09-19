/*
 Copyright 2025 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


locals {
  # Construct the Workload Identity Principal
  member_principal = "principal://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/${local.project_id}.svc.id.goog/subject/ns/default/sa/${kubernetes_service_account.ksa.metadata[0].name}"
  #Construct the CORRECTED Condition Expression (CEL) using startsWith()
  # CRITICAL: We add a trailing slash '/' to ensure we only match resources *under* the secret,
  # preventing accidental matches with similarly prefixed secret names (e.g., WANDB_API_KEY_BACKUP).
  CONDITION_EXPRESSION = "resource.name.startsWith('projects/${local.project_number}/locations/${var.region}/secrets/WANDB_API_KEY/') || resource.name.startsWith('projects/${local.project_number}/locations/${var.region}/secrets/CONDA_TOKEN/')"
}

resource "google_project_iam_binding" "gke_service_agent_network_user" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  members = [local.member_principal]
  condition {
    title       = "RestrictToRaySecretsV2"
    description = "Allow access to WANDB and CONDA secret versions (prefix match)"
    expression  = local.CONDITION_EXPRESSION
  }
  depends_on = [
    kubernetes_manifest.ray_cluster,
  ]
}


resource "google_storage_bucket_iam_member" "ksa_gcs_access" {
  bucket = var.bucket_name
  role   = "roles/storage.admin"
  member = "principal://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/${local.project_id}.svc.id.goog/subject/ns/default/sa/${var.ksa_name}"

}

resource "google_secret_manager_secret" "default" {
  secret_id = var.secret_name
  replication {
    # This syntax is correct for provider v6.47.0 and later.
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "ksa_secret_access" {
  secret_id = google_secret_manager_secret.default.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "principal://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/${local.project_id}.svc.id.goog/subject/ns/default/sa/${var.ksa_name}"
}
