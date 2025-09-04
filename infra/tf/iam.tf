# iam.tf

resource "google_secret_manager_secret" "default" {
  secret_id = var.secret_name
  replication {
    # This syntax is correct for provider v6.47.0 and later.
    auto {}
  }
}

resource "google_storage_bucket_iam_member" "ksa_gcs_access" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.admin"
  member = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/${var.ksa_name}"
}

resource "google_secret_manager_secret_iam_member" "ksa_secret_access" {
  secret_id = google_secret_manager_secret.default.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/${var.ksa_name}"
}

resource "google_project_iam_member" "gke_service_agent_network_user" {
  project = var.project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
}
