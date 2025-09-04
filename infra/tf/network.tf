# Create 3 x VPCs (2 x gVNIC for north/south traffic and 1 x RDMA for east/west traffic for GPU to GPU comms)

# networking.tf

# --------------------------------------------------------------------
# Management Network (for GKE control plane and node primary nic0)
# --------------------------------------------------------------------
resource "google_compute_network" "management" {
  name                    = "${var.management_network_prefix}-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "management" {
  name                     = "${var.management_network_prefix}-sub"
  ip_cidr_range            = var.management_cidr_range
  network                  = google_compute_network.management.name
  region                   = var.region
  private_ip_google_access = true
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
  network_profile         = "projects/${var.project_id}/global/networkProfiles/${var.zone}-vpc-roce"
}

resource "google_compute_subnetwork" "rdma" {
  count         = 8
  name          = "${var.rdma_network_prefix}-sub-${count.index}"
  ip_cidr_range = "${var.rdma_cidr_prefix}.${count.index + 1}.0/24"
  network       = google_compute_network.rdma.name
  region        = var.region
}
