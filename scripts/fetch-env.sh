#!/usr/bin/env bash
# Runs ON THE VM. Prints the latest version of a Secret Manager secret using the VM's
# own service account via the metadata server. No gcloud needed.
#
# Usage: scripts/fetch-env.sh [secret_name]
set -euo pipefail

SECRET_NAME="${1:-ghost-env}"
MD="http://metadata.google.internal/computeMetadata/v1"

PROJECT_ID=$(curl -fsS -H 'Metadata-Flavor: Google' "$MD/project/project-id")
TOKEN=$(curl -fsS -H 'Metadata-Flavor: Google' \
  "$MD/instance/service-accounts/default/token" | jq -r .access_token)

curl -fsS -H "Authorization: Bearer $TOKEN" \
  "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$SECRET_NAME/versions/latest:access" \
  | jq -r .payload.data | base64 -d
