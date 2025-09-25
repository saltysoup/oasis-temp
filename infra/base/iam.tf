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

resource "google_service_account" "default" {
  account_id   = var.gke_service_account_name
  display_name = "Service Account for Oasis Ray cluster"
}

resource "google_project_iam_member" "gke_service_account_roles" {
  project = local.project_id
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.default.email}"
}



resource "google_project_iam_member" "gke_service_agent_network_user" {
  project    = local.project_id
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com"
  depends_on = [google_project_service.services]
}
