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

resource "google_artifact_registry_repository" "oasis" {
  location               = var.region
  repository_id          = "oasis"
  description            = "Oasis docker repository"
  format                 = "DOCKER"
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }
  cleanup_policies {
    id     = "keep-new-untagged"
    action = "KEEP"
    condition {
      tag_state  = "UNTAGGED"
      newer_than = "7d"
    }
  }
  cleanup_policies {
    id     = "keep-tagged-release"
    action = "KEEP"
    condition {
      tag_state = "TAGGED"
    }
  }
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 2
    }
  }
}

resource "google_artifact_registry_repository" "docker-hub" {
  location      = var.region
  repository_id = "docker-hub"
  description   = "Docker Hub remote docker repository"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "docker hub"
    docker_repository {
      public_repository = "DOCKER_HUB"
    }
  }
}

resource "google_artifact_registry_repository" "oasis-virtual" {
  location      = var.region
  repository_id = "oasis-virtual"
  description   = "Oasis virtual docker repository"
  format        = "DOCKER"
  mode          = "VIRTUAL_REPOSITORY"
  virtual_repository_config {
    upstream_policies {
      id         = "oasis"
      repository = google_artifact_registry_repository.oasis.id
      priority   = 20
    }
    upstream_policies {
      id         = "docker-hub"
      repository = google_artifact_registry_repository.docker-hub.id
      priority   = 10
    }
  }
}

resource "google_artifact_registry_repository" "oasis-python" {
  location      = var.region
  repository_id = "oasis-python"
  description   = "Oasis Python repository"
  format        = "PYTHON"
}

resource "google_artifact_registry_repository" "pypi" {
  location      = var.region
  repository_id = "pypi"
  description   = "Pypi remote repository"
  format        = "PYTHON"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "pypi"
    python_repository {
      public_repository = "PYPI"
    }
  }
}

resource "google_artifact_registry_repository" "oasis-python-virtual" {
  location      = var.region
  repository_id = "oasis-python-virtual"
  description   = "Oasis virtual Python repository"
  format        = "PYTHON"
  mode          = "VIRTUAL_REPOSITORY"
  virtual_repository_config {
    upstream_policies {
      id         = "oasis-python"
      repository = google_artifact_registry_repository.oasis-python.id
      priority   = 20
    }
    upstream_policies {
      id         = "pypi"
      repository = google_artifact_registry_repository.pypi.id
      priority   = 10
    }
  }
}
