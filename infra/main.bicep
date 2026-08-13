metadata description = 'Provisions the Serverless Blob Manager environment: managed storage, function app and Event Grid routing.'

targetScope = 'subscription'

@description('Name of the AZD environment. Used to name the resource group and to tag every resource.')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary Azure region for this deployment.')
@minLength(1)
param location string

@description('Object id of the user or service principal running the deployment. When set, it receives blob data access on the managed storage account for local debugging.')
param principalId string = ''

@description('Set to false to skip the Event Grid Viewer web app and its subscription.')
param deployEventGridViewer bool = true

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var resourceGroupName = 'rg-${environmentName}'
var tags = { 'azd-env-name': environmentName }

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storage 'modules/storage.bicep' = {
  scope: resourceGroup
  name: 'storage'
  params: {
    name: 'stdata${resourceToken}'
    location: location
    tags: tags
  }
}

module functionApp 'modules/functionApp.bicep' = {
  scope: resourceGroup
  name: 'functionApp'
  params: {
    name: 'func-${resourceToken}'
    location: location
    tags: tags
    hostingPlanName: 'plan-${resourceToken}'
    functionStorageAccountName: 'stfunc${resourceToken}'
    applicationInsightsName: 'appi-${resourceToken}'
    managedStorageAccountName: storage.outputs.name
  }
}

module functionAppStorageAccess 'modules/storageRoleAssignment.bicep' = {
  scope: resourceGroup
  name: 'functionAppStorageAccess'
  params: {
    storageAccountName: storage.outputs.name
    principalId: functionApp.outputs.principalId
  }
}

module developerStorageAccess 'modules/storageRoleAssignment.bicep' = if (!empty(principalId)) {
  scope: resourceGroup
  name: 'developerStorageAccess'
  params: {
    storageAccountName: storage.outputs.name
    principalId: principalId
    principalType: 'User'
  }
}

module eventGrid 'modules/eventGrid.bicep' = {
  scope: resourceGroup
  name: 'eventGrid'
  params: {
    name: 'evgt-${resourceToken}'
    location: location
    tags: tags
    storageAccountId: storage.outputs.id
  }
}

module eventGridViewer 'modules/eventGridViewer.bicep' = if (deployEventGridViewer) {
  scope: resourceGroup
  name: 'eventGridViewer'
  params: {
    name: 'app-viewer-${resourceToken}'
    location: location
    tags: tags
    hostingPlanName: 'plan-viewer-${resourceToken}'
    eventGridTopicName: eventGrid.outputs.name
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name
output SERVICE_FUNC_NAME string = functionApp.outputs.name
output SERVICE_FUNC_URI string = functionApp.outputs.uri
output MANAGED_STORAGE_ACCOUNT_NAME string = storage.outputs.name
output MANAGED_STORAGE_CONTAINER_NAME string = storage.outputs.containerName
output EVENT_GRID_TOPIC_NAME string = eventGrid.outputs.name
output EVENT_GRID_SUBSCRIPTION_NAME string = 'blobdeleted-sub'
output EVENT_GRID_FUNCTION_NAME string = 'BlobDeletedFunction'
output EVENT_GRID_VIEWER_URI string = deployEventGridViewer ? eventGridViewer!.outputs.uri : ''
