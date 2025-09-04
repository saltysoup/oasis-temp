# Set variables (confirmed from your logs)
export GKE_PROJECT_ID="nm-ai-sandbox"
export GKE_PROJECT_NUMBER="820082097244"
export SECRETS_PROJECT_NUMBER="820082097244"
export SECRET_LOCATION="australia-southeast1"
export KSA_NAME="oasis-ray"
export NAMESPACE="default"

# 1. Construct the Workload Identity Principal
MEMBER_PRINCIPAL="principal://iam.googleapis.com/projects/${GKE_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GKE_PROJECT_ID}.svc.id.goog/subject/ns/${NAMESPACE}/sa/${KSA_NAME}"

# 2. Construct the CORRECTED Condition Expression (CEL) using startsWith()
# CRITICAL: We add a trailing slash '/' to ensure we only match resources *under* the secret, 
# preventing accidental matches with similarly prefixed secret names (e.g., WANDB_API_KEY_BACKUP).
CONDITION_EXPRESSION="resource.name.startsWith('projects/${SECRETS_PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/WANDB_API_KEY/') || resource.name.startsWith('projects/${SECRETS_PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/CONDA_TOKEN/')"

echo "Applying corrected IAM binding for Principal: $MEMBER_PRINCIPAL"

# 3. Apply the IAM policy binding to the Secrets Project
# We use a new title (e.g., 'RestrictToRaySecretsV2') to distinguish it from the previous, incorrect binding.
gcloud projects add-iam-policy-binding $SECRETS_PROJECT_NUMBER \
    --role=roles/secretmanager.secretAccessor \
    --member="$MEMBER_PRINCIPAL" \
    --condition="title=RestrictToRaySecretsV2,description=Allow access to WANDB and CONDA secret versions (prefix match),expression=${CONDITION_EXPRESSION}"