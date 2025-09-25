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


# GKE standard cluster with 2 node pools (DWS flex and Spot) using RDMA networking. Used by custom compute class for scaling out GPU nodes

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

resource "google_gke_hub_fleet" "default" {
  display_name = "Oasis GKE fleet"

  default_cluster_config {
    binary_authorization_config {
      evaluation_mode = "POLICY_BINDINGS"
    }
    security_posture_config {
      mode               = "BASIC"
      vulnerability_mode = "VULNERABILITY_BASIC"
    }
  }
  depends_on = [
    google_project_service.services,
  ]
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # The cluster uses your new custom management VPC for its control plane.
  network    = google_compute_network.management.name
  subnetwork = google_compute_subnetwork.management.name

  fleet {
    project = google_gke_hub_fleet.default.project
  }

  # Ensure the cluster waits for ALL networks and permissions to be created.
  depends_on = [
    google_project_service.services,
    google_compute_subnetwork.management,
    google_compute_subnetwork.gvnics,
    google_compute_subnetwork.rdma,
    google_project_iam_member.gke_service_agent_network_user
  ]

  deletion_protection      = false
  initial_node_count       = 1
  remove_default_node_pool = false

  node_config {
    machine_type    = "e2-standard-32"
    service_account = google_service_account.default.email
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    gcfs_config {
      # This enables image streaming for the node pool
      # The cluster-level config will still indicate that
      # image streaming is disabled.
      enabled = true
    }
  }
  node_locations = [var.zone]

  networking_mode         = "VPC_NATIVE"
  datapath_provider       = "ADVANCED_DATAPATH"
  enable_multi_networking = true

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = false
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.client_ip
      display_name = "Client IP"
    }
  }

  # See: https://cloud.google.com/kubernetes-engine/docs/add-on/ray-on-gke/how-to/collect-view-logs-metrics#requirements_and_limitations
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
    ]
  }

  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }

  addons_config {
    gcs_fuse_csi_driver_config { enabled = true }
    ray_operator_config {
      enabled = true
      # See: https://cloud.google.com/kubernetes-engine/docs/add-on/ray-on-gke/how-to/collect-view-logs-metrics
      ray_cluster_logging_config {
        enabled = true
      }
      ray_cluster_monitoring_config {
        enabled = true
      }
    }

  }

  cost_management_config {
    enabled = true
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  secret_manager_config { enabled = true }

  workload_identity_config { workload_pool = "${local.project_id}.svc.id.goog" }

  enable_shielded_nodes = true

}

resource "google_container_node_pool" "primary_h200" {
  provider = google-beta

  name               = var.nodepool_name
  cluster            = google_container_cluster.primary.name
  location           = var.region
  initial_node_count = 0

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
    enable_private_nodes = true
  }

  node_config {
    machine_type     = var.machine_type
    spot             = false
    disk_size_gb     = 100
    disk_type        = "hyperdisk-balanced"
    max_run_duration = "604800s"
    service_account  = google_service_account.default.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # UPDATED: Changed from a block to a boolean argument, per the error message.
    flex_start = true

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
    ephemeral_storage_local_ssd_config {
      data_cache_count = 0
      local_ssd_count  = 32
    }
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
    gcfs_config {
      enabled = true
    }
  }

}



resource "google_container_node_pool" "spot_h200" {
  provider = google-beta

  name               = var.nodepool_name_spot
  cluster            = google_container_cluster.primary.name
  location           = var.region
  initial_node_count = 0

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
    enable_private_nodes = true
  }

  node_config {
    machine_type    = var.machine_type
    spot            = true
    service_account = google_service_account.default.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

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
    ephemeral_storage_local_ssd_config {
      data_cache_count = 0
      local_ssd_count  = 32
    }
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
    gcfs_config {
      enabled = true
    }
  }
}
