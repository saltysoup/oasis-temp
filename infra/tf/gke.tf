# GKE standard cluster with 2 node pools (DWS flex and Spot) using RDMA networking. Used by custom compute class for scaling out GPU nodes

# gke.tf

locals {
  # This list contains the 9 additional networks (1 GVNIC + 8 RDMA)
  # to be attached to each node's additional interfaces. The first GVNIC networking is inherited from cluster
  all_additional_node_networks = concat(
    [{
      network    = google_compute_network.gvnics.name
      subnetwork = google_compute_subnetwork.gvnics.name
    }],
    [
      for i in range(8) : {
        network    = google_compute_network.rdma.name
        subnetwork = google_compute_subnetwork.rdma[i].name
      }
    ]
  )
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # The cluster uses your new custom management VPC for its control plane.
  network    = google_compute_network.management.name
  subnetwork = google_compute_subnetwork.management.name

  # Ensure the cluster waits for ALL networks and permissions to be created.
  depends_on = [
    google_compute_subnetwork.management,
    google_compute_subnetwork.gvnics,
    google_compute_subnetwork.rdma,
    google_project_iam_member.gke_service_agent_network_user
  ]

  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = false
  node_config {
    machine_type = "e2-standard-32"
  }
  node_locations = [var.zone]

  networking_mode         = "VPC_NATIVE"
  datapath_provider       = "ADVANCED_DATAPATH"
  enable_multi_networking = true

  addons_config {
    gcs_fuse_csi_driver_config { enabled = true }
    ray_operator_config { enabled = true }
  }
  secret_manager_config { enabled = true }
  workload_identity_config { workload_pool = "${var.project_id}.svc.id.goog" }
}

resource "google_container_node_pool" "primary_h200" {
  provider = google-beta

  name       = var.nodepool_name
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
  }

  network_config {
    dynamic "additional_node_network_configs" {
      for_each = local.all_additional_node_networks
      content {
        network    = additional_node_network_configs.value.network
        subnetwork = additional_node_network_configs.value.subnetwork
      }
    }
  }

  node_config {
    machine_type = var.machine_type
    spot         = false

    # UPDATED: Changed from a block to a boolean argument, per the error message.
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
    labels = { "cloud.google.com/compute-class" = "h200-ccc" }
    taint {
      key    = "cloud.google.com/compute-class"
      value  = "h200-ccc"
      effect = "NO_SCHEDULE"
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}

resource "google_container_node_pool" "spot_h200" {
  provider = google-beta

  name       = var.nodepool_name_spot
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 0

  autoscaling {
    min_node_count = 0
    max_node_count = var.total_max_nodes
  }

  management {
    auto_repair = false
  }

  network_config {
    dynamic "additional_node_network_configs" {
      for_each = local.all_additional_node_networks
      content {
        network    = additional_node_network_configs.value.network
        subnetwork = additional_node_network_configs.value.subnetwork
      }
    }
  }

  node_config {
    machine_type = var.machine_type
    spot         = true
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
    labels = { "cloud.google.com/compute-class" = "h200-ccc" }
    taint {
      key    = "cloud.google.com/compute-class"
      value  = "h200-ccc"
      effect = "NO_SCHEDULE"
    }
    reservation_affinity { consume_reservation_type = "NO_RESERVATION" }
  }
}
