#!/usr/bin/env bash
# Creates the Event Grid subscription that routes BlobDeleted events to the function.
# Runs as an azd postdeploy hook: the Azure Function endpoint must already exist,
# so the subscription cannot be created during provisioning.
set -euo pipefail

for variable in AZURE_SUBSCRIPTION_ID AZURE_RESOURCE_GROUP EVENT_GRID_TOPIC_NAME EVENT_GRID_SUBSCRIPTION_NAME EVENT_GRID_FUNCTION_NAME SERVICE_FUNC_NAME; do
  if [ -z "${!variable:-}" ]; then
    echo "Missing environment variable '$variable'. Run 'azd provision' first." >&2
    exit 1
  fi
done

function_resource_id="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Web/sites/${SERVICE_FUNC_NAME}/functions/${EVENT_GRID_FUNCTION_NAME}"

echo "Creating Event Grid subscription '${EVENT_GRID_SUBSCRIPTION_NAME}' on topic '${EVENT_GRID_TOPIC_NAME}'..."

az eventgrid system-topic event-subscription create \
  --name "${EVENT_GRID_SUBSCRIPTION_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --system-topic-name "${EVENT_GRID_TOPIC_NAME}" \
  --subscription "${AZURE_SUBSCRIPTION_ID}" \
  --endpoint-type azurefunction \
  --endpoint "${function_resource_id}" \
  --included-event-types Microsoft.Storage.BlobDeleted \
  --max-events-per-batch 1 \
  --output none

echo "Event Grid subscription is up to date."
