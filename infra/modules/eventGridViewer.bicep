metadata description = 'Creates the Azure Event Grid Viewer web app and subscribes it to the storage system topic.'

@description('The name of the event grid viewer web app.')
param name string

@description('The location where you want to create the resources.')
param location string = resourceGroup().location

@description('Tags applied to every resource created by this module.')
param tags object = {}

@description('The name of the app service plan hosting the event grid viewer.')
param hostingPlanName string

@description('The name of the event grid system topic the viewer subscribes to.')
param eventGridTopicName string

@description('The name of the event subscription created for the viewer.')
param subscriptionName string = 'eventviewer-sub'

var viewerRepoUrl = 'https://github.com/azure-samples/azure-event-grid-viewer.git'

resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    name: 'F1'
    tier: 'Free'
    size: 'F1'
    family: 'F'
    capacity: 0
  }
  kind: 'app'
  properties: {}
}

resource viewerAppService 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v6.0'
    }
    httpsOnly: true
  }
}

resource viewerAppServiceDeploy 'Microsoft.Web/sites/sourcecontrols@2023-12-01' = {
  parent: viewerAppService
  name: 'web'
  properties: {
    repoUrl: viewerRepoUrl
    branch: 'main'
    isManualIntegration: true
  }
}

resource systemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' existing = {
  name: eventGridTopicName
}

resource viewerSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  parent: systemTopic
  name: subscriptionName
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: 'https://${viewerAppService.properties.defaultHostName}/api/updates'
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobDeleted'
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
  dependsOn: [
    viewerAppServiceDeploy
  ]
}

output name string = viewerAppService.name
output uri string = 'https://${viewerAppService.properties.defaultHostName}'
