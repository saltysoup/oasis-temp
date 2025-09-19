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

resource "kubernetes_manifest" "gkenetworkparamset_rdma_0" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-0"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-0"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_0" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-0"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-0"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_1" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-1"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-1"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_1" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-1"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-1"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_2" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-2"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-2"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_2" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-2"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-2"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_3" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-3"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-3"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_3" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-3"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-3"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_4" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-4"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-4"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_4" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-4"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-4"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_5" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-5"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-5"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_5" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-5"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-5"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_6" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-6"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-6"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_6" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-6"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-6"
      }
      "type" = "Device"
    }
  }
}

resource "kubernetes_manifest" "gkenetworkparamset_rdma_7" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "GKENetworkParamSet"
    "metadata" = {
      "name" = "rdma-7"
    }
    "spec" = {
      "deviceMode" = "RDMA"
      "vpc"        = "${var.rdma_network_prefix}-net"
      "vpcSubnet"  = "${var.rdma_network_prefix}-sub-7"
    }
  }
}

resource "kubernetes_manifest" "network_rdma_7" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "Network"
    "metadata" = {
      "name" = "rdma-7"
    }
    "spec" = {
      "parametersRef" = {
        "group" = "networking.gke.io"
        "kind"  = "GKENetworkParamSet"
        "name"  = "rdma-7"
      }
      "type" = "Device"
    }
  }
}
