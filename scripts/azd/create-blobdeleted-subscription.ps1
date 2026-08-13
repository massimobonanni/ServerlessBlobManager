<#
.SYNOPSIS
    Creates the Event Grid subscription that routes BlobDeleted events to the function.
.DESCRIPTION
    Runs as an azd postdeploy hook: the Azure Function endpoint must already exist,
    so the subscription cannot be created during provisioning.
#>
$ErrorActionPreference = 'Stop'

$requiredVariables = @(
    'AZURE_SUBSCRIPTION_ID',
    'AZURE_RESOURCE_GROUP',
    'EVENT_GRID_TOPIC_NAME',
    'EVENT_GRID_SUBSCRIPTION_NAME',
    'EVENT_GRID_FUNCTION_NAME',
    'SERVICE_FUNC_NAME'
)

foreach ($variable in $requiredVariables) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($variable))) {
        throw "Missing environment variable '$variable'. Run 'azd provision' first."
    }
}

$functionResourceId = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$env:SERVICE_FUNC_NAME/functions/$env:EVENT_GRID_FUNCTION_NAME"

Write-Host "Creating Event Grid subscription '$env:EVENT_GRID_SUBSCRIPTION_NAME' on topic '$env:EVENT_GRID_TOPIC_NAME'..."

az eventgrid system-topic event-subscription create `
    --name $env:EVENT_GRID_SUBSCRIPTION_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --system-topic-name $env:EVENT_GRID_TOPIC_NAME `
    --subscription $env:AZURE_SUBSCRIPTION_ID `
    --endpoint-type azurefunction `
    --endpoint $functionResourceId `
    --included-event-types Microsoft.Storage.BlobDeleted `
    --max-events-per-batch 1 `
    --output none

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create the Event Grid subscription."
}

Write-Host "Event Grid subscription is up to date."
