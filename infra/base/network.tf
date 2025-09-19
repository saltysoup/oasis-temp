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

# Create 3 x VPCs (2 x gVNIC for north/south traffic and 1 x RDMA for east/west traffic for GPU to GPU comms)

# --------------------------------------------------------------------
# Management Network (for GKE control plane and node primary nic0)
# --------------------------------------------------------------------
resource "google_compute_network" "management" {
  name                    = "${var.management_network_prefix}-net"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services]
}

resource "google_compute_subnetwork" "management" {
  name                     = "${var.management_network_prefix}-sub"
  ip_cidr_range            = var.management_cidr_range
  network                  = google_compute_network.management.name
  region                   = var.region
  private_ip_google_access = true
}

# --------------------------------------------------------------------
# Proxy-only subnetwork for internal load balancers
# --------------------------------------------------------------------
resource "google_compute_subnetwork" "proxy_only" {
  name          = "proxy-only-sub"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  ip_cidr_range = var.proxy_only_cidr_range
  network       = google_compute_network.management.name
  region        = var.region
}

resource "google_compute_firewall" "management_internal" {
  name    = "${var.management_network_prefix}-internal"
  network = google_compute_network.management.name
  allow {
    protocol = "all"
  }
  source_ranges = [var.management_cidr_range]
}

# ----------------------------------
# Primary GVNIC Network (for nic1)
# ----------------------------------
resource "google_compute_network" "gvnics" {
  name                    = "${var.gvnic_network_prefix}-net"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services]
}

resource "google_compute_subnetwork" "gvnics" {
  name                     = "${var.gvnic_network_prefix}-sub"
  ip_cidr_range            = var.gvnic_cidr_range
  network                  = google_compute_network.gvnics.name
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_firewall" "gvnics_internal" {
  name    = "${var.gvnic_network_prefix}-internal"
  network = google_compute_network.gvnics.name
  allow {
    protocol = "all"
  }
  source_ranges = [var.firewall_source_range]
}

# ----------------------------------
# RDMA HPC Network (for nic2-nic9)
# ----------------------------------
resource "google_compute_network" "rdma" {
  name                    = "${var.rdma_network_prefix}-net"
  auto_create_subnetworks = false
  network_profile         = "projects/${local.project_id}/global/networkProfiles/${var.zone}-vpc-roce"
  depends_on              = [google_project_service.services]
}

resource "google_compute_subnetwork" "rdma" {
  count         = 8
  name          = "${var.rdma_network_prefix}-sub-${count.index}"
  ip_cidr_range = "${var.rdma_cidr_prefix}.${count.index + 1}.0/24"
  network       = google_compute_network.rdma.name
  region        = var.region
}
