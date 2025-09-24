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
resource "google_compute_global_address" "build_worker_range" {
  name          = "worker-pool-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.management.id
}

resource "google_service_networking_connection" "build_worker_pool_conn" {
  network                 = google_compute_network.management.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.build_worker_range.name]
  depends_on              = [google_project_service.services]
}

resource "google_cloudbuild_worker_pool" "build_worker_pool" {
  name     = "oasis-build-pool"
  location = var.region
  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-highmem-8"
    no_external_ip = false
  }
  network_config {
    peered_network          = google_compute_network.management.id
    peered_network_ip_range = "/29"
  }
  depends_on = [google_service_networking_connection.build_worker_pool_conn]
}
