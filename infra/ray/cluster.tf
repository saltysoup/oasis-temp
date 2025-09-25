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

# Retrieve an access token as the Terraform runner
resource "kubernetes_service_account" "ksa" {
  metadata {
    name = var.ksa_name
  }
}

resource "kubernetes_manifest" "ccc" {
  manifest = yamldecode(file("manifests/ccc.yaml"))
}

resource "kubernetes_manifest" "nccl_rdma_installer" {
  manifest = yamldecode(file("manifests/nccl-rdma-installer.yaml"))
}



resource "kubernetes_manifest" "gkenetworkparamset_gvnic_1" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "gvnic-1"
    }
    "spec" = {
      "deviceMode" = "NetDevice"
      "vpc"        = "${var.gvnic_network_prefix}-net"
      "vpcSubnet"  = "${var.gvnic_network_prefix}-sub"
    }
  }
}

resource "kubernetes_manifest" "network_gvnic_1" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "gvnic-1"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "gvnic-1"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma" {
  count = 8
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-${count.index}"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-${count.index}"
    }
  }
}

resource "kubernetes_manifest" "network_rdma" {
  count = 8
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-${count.index}"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-${count.index}"
      }
      "type" = "Device"
    }
  }
  depends_on = [kubernetes_manifest.gkenetworkparamset_rdma]
}
