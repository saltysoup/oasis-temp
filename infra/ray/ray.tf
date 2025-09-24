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

resource "kubernetes_manifest" "ray_cluster" {
  manifest = {
    "apiVersion" = "ray.io/v1"
    "kind"       = "RayCluster"
    "metadata" = {
      "name"      = "ray-cluster-ccc"
      "namespace" = "default"
    }
    "spec" = {
      "autoscalerOptions" = {
        "idleTimeoutSeconds" = var.ray_cluster_idle_timeout_seconds
      }
      "enableInTreeAutoscaling" = true
      "headGroupSpec" = {
        "rayStartParams" = {
          "dashboard-host" = "0.0.0.0"
        }
        "template" = {
          "metadata" = {
            "annotations" = {
              "gke-gcsfuse/cpu-limit"               = "0"
              "gke-gcsfuse/ephemeral-storage-limit" = "0"
              "gke-gcsfuse/memory-limit"            = "0"
              "gke-gcsfuse/volumes"                 = "true"
            }
          }
          "spec" = {
            "containers" = [
              {
                "env" = [
                  {
                    "name"  = "RAY_enable_autoscaler_v2"
                    "value" = "1"
                  },
                ]
                "image" = "${local.ray_server_image}"
                "name"  = "ray-head"
                "ports" = [
                  {
                    "containerPort" = 6379
                    "name"          = "gcs-server"
                  },
                  {
                    "containerPort" = 8265
                    "name"          = "dashboard"
                  },
                  {
                    "containerPort" = 10001
                    "name"          = "client"
                  },
                ]
                "resources" = {
                  "limits" = {
                    "cpu"               = "8"
                    "ephemeral-storage" = "9Gi"
                    "memory"            = "16G"
                  }
                  "requests" = {
                    "cpu"               = "8"
                    "ephemeral-storage" = "9Gi"
                    "memory"            = "16G"
                  }
                }
                "volumeMounts" = [
                  {
                    "mountPath" = "/tmp/ray"
                    "name"      = "ray-logs"
                  },
                  {
                    "mountPath" = "/bucket"
                    "name"      = "gcs-fuse-csi-eph"
                  },
                ]
              },
            ]
            "nodeSelector" = {
              "cloud.google.com/gke-nodepool" = "default-pool"
            }
            "restartPolicy"      = "Never"
            "serviceAccountName" = "${kubernetes_service_account.ksa.metadata[0].name}"
            "volumes" = [
              {
                "emptyDir" = {}
                "name"     = "ray-logs"
              },
              {
                "csi" = {
                  "driver" = "gcsfuse.csi.storage.gke.io"
                  "volumeAttributes" = {
                    "bucketName"                     = var.bucket_name
                    "gcsfuseMetadataPrefetchOnMount" = "true"
                    "mountOptions"                   = "implicit-dirs,file-mode=777,dir-mode=777,file-cache:enable-parallel-downloads:true,file-cache:cache-file-for-range-read:true,file-cache:max-size-mb:-1,write:enable-streaming-writes:true,read_ahead_kb=1024,file-system:kernel-list-cache-ttl-secs:-1"
                  }
                }
                "name" = "gcs-fuse-csi-eph"
              },
            ]
          }
        }
      }
      "rayVersion" = var.ray_version
      "workerGroupSpecs" = [
        {
          "groupName"   = "gpu-group"
          "replicas"    = 0
          "maxReplicas" = 10
          "minReplicas" = 0
          "rayStartParams" = {
            "num-cpus" = "220"
          }

          "template" = {
            "metadata" = {
              "annotations" = {
                "gke-gcsfuse/cpu-limit"               = "0"
                "gke-gcsfuse/ephemeral-storage-limit" = "0"
                "gke-gcsfuse/memory-limit"            = "0"
                "gke-gcsfuse/volumes"                 = "true"
                "networking.gke.io/default-interface" = "eth0"
                "networking.gke.io/interfaces"        = <<-EOT
                [
                  {"interfaceName":"eth0","network":"default"},
                  {"interfaceName":"eth1","network":"gvnic-1"},
                  {"interfaceName":"eth2","network":"rdma-0"},
                  {"interfaceName":"eth3","network":"rdma-1"},
                  {"interfaceName":"eth4","network":"rdma-2"},
                  {"interfaceName":"eth5","network":"rdma-3"},
                  {"interfaceName":"eth6","network":"rdma-4"},
                  {"interfaceName":"eth7","network":"rdma-5"},
                  {"interfaceName":"eth8","network":"rdma-6"},
                  {"interfaceName":"eth9","network":"rdma-7"}
                ]

                EOT
              }
            }
            "spec" = {
              "containers" = [
                {
                  "command" = [
                    "source /usr/local/gib/scripts/set_nccl_env.sh",
                  ]
                  "env" = [
                    {
                      "name"  = "LD_LIBRARY_PATH"
                      "value" = "/usr/local/nvidia/lib64"
                    },
                  ]
                  "image" = "${local.ray_server_image}"
                  "name"  = "ray-worker"
                  "resources" = {
                    "limits" = {
                      "cpu"               = "220"
                      "ephemeral-storage" = "1000Gi"
                      "memory"            = "2800Gi"
                      "nvidia.com/gpu"    = "8"
                    }
                    "requests" = {
                      "cpu"               = "220"
                      "ephemeral-storage" = "1000Gi"
                      "memory"            = "2800Gi"
                      "nvidia.com/gpu"    = "8"
                    }
                  }
                  "volumeMounts" = [
                    {
                      "mountPath" = "/usr/local/nvidia"
                      "name"      = "nvidia"
                    },
                    {
                      "mountPath" = "/usr/local/gib"
                      "name"      = "gib"
                    },
                    {
                      "mountPath" = "/dev/shm"
                      "name"      = "shared-memory"
                    },
                    {
                      "mountPath" = "/tmp"
                      "name"      = "ray-tmp-storage"
                    },
                    {
                      "mountPath" = "/bucket"
                      "name"      = "gcs-fuse-csi-eph"
                    },
                  ]
                },
              ]
              "nodeSelector" = {
                "cloud.google.com/compute-class" = "h200-ccc"
              }
              "restartPolicy"      = "Never"
              "serviceAccountName" = "oasis-ray"
              "tolerations" = [
                {
                  "effect"   = "NoSchedule"
                  "key"      = "nvidia.com/gpu"
                  "operator" = "Exists"
                },
              ]
              "volumes" = [
                {
                  "hostPath" = {
                    "path" = "/home/kubernetes/bin/gib"
                  }
                  "name" = "gib"
                },
                {
                  "hostPath" = {
                    "path" = "/home/kubernetes/bin/nvidia"
                  }
                  "name" = "nvidia"
                },
                {
                  "hostPath" = {
                    "path" = "/lib64"
                  }
                  "name" = "lib64"
                },
                {
                  "emptyDir" = {
                    "medium"    = "Memory"
                    "sizeLimit" = "250Gi"
                  }
                  "name" = "shared-memory"
                },
                {
                  "hostPath" = {
                    "path" = "/sys"
                  }
                  "name" = "sys"
                },
                {
                  "hostPath" = {
                    "path" = "/proc/sys"
                  }
                  "name" = "proc-sys"
                },
                {
                  "emptyDir" = {}
                  "name"     = "ray-tmp-storage"
                },
                {
                  "csi" = {
                    "driver" = "gcsfuse.csi.storage.gke.io"
                    "volumeAttributes" = {
                      "bucketName"                     = var.bucket_name
                      "gcsfuseMetadataPrefetchOnMount" = "true"
                      "mountOptions"                   = "implicit-dirs,file-mode=777,dir-mode=777,file-cache:enable-parallel-downloads:true,file-cache:cache-file-for-range-read:true,file-cache:max-size-mb:-1,write:enable-streaming-writes:true,read_ahead_kb=1024,file-system:kernel-list-cache-ttl-secs:-1"
                    }
                  }
                  "name" = "gcs-fuse-csi-eph"
                },
              ]
            }
          }
        },
      ]
    }
  }
  depends_on = [
    kubernetes_manifest.ccc,
    kubernetes_manifest.gkenetworkparamset_gvnic_1,
    kubernetes_manifest.network_rdma,
  ]
}

resource "kubernetes_manifest" "ray_dashboard" {
  manifest = yamldecode(file("manifests/dashboard.yaml"))
  depends_on = [
    kubernetes_manifest.ray_cluster,
  ]
}

resource "kubernetes_manifest" "ray_dashboard_ingress" {
  manifest = yamldecode(file("manifests/ingress.yaml"))
  depends_on = [
    kubernetes_manifest.ray_dashboard,
  ]
}
