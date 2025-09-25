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

# See https://cloud.google.com/binary-authorization/docs/policy-yaml-reference
# for definitions of the various values
resource "google_binary_authorization_policy" "policy" {
  global_policy_evaluation_mode = "ENABLE"
  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "DRYRUN_AUDIT_LOG_ONLY"
    require_attestations_by = ["projects/${local.project_id}/attestors/built-by-cloud-build"]
  }
}
