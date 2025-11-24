# GKE standard cluster with 4 node pools (on-demand, on-demand with GPU MIG, spot and DWS flex).
# Used by custom compute class for scaling out GPU nodes, except for GPU MIG nodepool (roadmap in Q1 2026)

# gke.tf

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # The cluster uses your new custom management VPC for its control plane.
  network    = google_compute_network.management.name
  subnetwork = google_compute_subnetwork.management.name

  # Ensure the cluster waits for ALL networks and permissions to be created.
  depends_on = [
    google_compute_subnetwork.management,
    google_project_iam_member.gke_service_agent_network_user
  ]

  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = false
  node_config {
    machine_type = "e2-standard-8"
  }
  node_locations = [var.zone]

  networking_mode         = "VPC_NATIVE"
  datapath_provider       = "ADVANCED_DATAPATH"
  enable_multi_networking = true

  addons_config {
    gcs_fuse_csi_driver_config { enabled = true }

  }
  secret_manager_config { enabled = true }
  workload_identity_config { workload_pool = "${var.project_id}.svc.id.goog" }
}

resource "google_container_node_pool" "b40-ondemand-ccc" {
  provider = google-beta

  name       = var.nodepool_name_ondemand
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 0

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = var.total_max_nodes
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    spot         = false
    flex_start   = false

    gvnic {
      enabled = true
    }
    guest_accelerator {
      type  = var.gpu_type
      count = var.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }
    }
    labels = { "cloud.google.com/compute-class" = "b40-ccc" } # has to match the compute class name in ccc.yaml
    taint {
      key    = "cloud.google.com/compute-class"
      value  = "b40-ccc"
      effect = "NO_SCHEDULE"
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}

# not using ccc as gpu mig not supported yet
resource "google_container_node_pool" "b40-ondemand-mig" {
  provider = google-beta

  name       = var.nodepool_name_mig
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 0

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = var.total_max_nodes
  }

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    spot         = false
    flex_start   = false

    gvnic {
      enabled = true
    }
    guest_accelerator {
      type  = var.gpu_type_mig
      gpu_partition_size = var.gpu_partition_size_mig
      count = var.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}

resource "google_container_node_pool" "b40-spot-ccc" {
  provider = google-beta

  name       = var.nodepool_name_spot
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 0

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = var.total_max_nodes
  }

  management {
    auto_repair = false
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    spot         = true
    flex_start   = false

    gvnic {
      enabled = true
    }
    guest_accelerator {
      type  = var.gpu_type
      count = var.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }
    }
    labels = { "cloud.google.com/compute-class" = "b40-ccc" } # has to match the compute class name in ccc.yaml
    taint {
      key    = "cloud.google.com/compute-class"
      value  = "b40-ccc"
      effect = "NO_SCHEDULE"
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}
resource "google_container_node_pool" "b40-dws-ccc" {
  provider = google-beta

  name       = var.nodepool_name_dws
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 0

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = var.total_max_nodes
  }

  management {
    auto_repair = false
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    spot         = false
    flex_start   = true

    gvnic {
      enabled = true
    }
    guest_accelerator {
      type  = var.gpu_type
      count = var.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }
    }
    labels = { "cloud.google.com/compute-class" = "b40-ccc" } # has to match the compute class name in ccc.yaml
    taint {
      key    = "cloud.google.com/compute-class"
      value  = "b40-ccc"
      effect = "NO_SCHEDULE"
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}