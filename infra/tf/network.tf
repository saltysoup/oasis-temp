# Create 1 x VPC

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
