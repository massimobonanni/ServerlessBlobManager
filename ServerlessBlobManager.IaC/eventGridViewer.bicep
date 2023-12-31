@description('The location where you want to create the resources.')
param location string = resourceGroup().location

@description('The name of the environment. It will be used to create the name of the resources in the resource group.')
@maxLength(16)
@minLength(3)
param environmentName string = 'sbm${uniqueString(subscription().id, resourceGroup().name)}'

@description('The name of the event grid topic to which the event grid viewer will be subscribe.')
param eventGridTopicName string

//-------------------------------------------------------------
// EventGrid Event Viewer
//-------------------------------------------------------------
var eventViewerAppName =toLower('${environmentName}-eventviewer')
var eventViewerAppPlanName=toLower('${environmentName}-eventviewerplan')
var viewerRepoUrl = 'https://github.com/azure-samples/azure-event-grid-viewer.git'

resource eventViewerAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: eventViewerAppPlanName
  location: location
  sku: {
    name: 'F1'
    tier: 'Free'
    size: 'F1'
    family: 'F'
    capacity: 0
  }
  properties: {}
  kind: 'app'
}

resource eventViewerAppService 'Microsoft.Web/sites@2022-03-01' = {
  name: eventViewerAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: eventViewerAppServicePlan.id
    hostNameSslStates: [
      {
        hostType: 'Standard'
        sslState: 'Disabled'
        name: '${eventViewerAppName}.azurewebsites.net'
      }
      {
        hostType: 'Standard'
        sslState: 'Disabled'
        name: '${eventViewerAppName}.scm.azurewebsites.net'
      }
    ]
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion:'v6.0'
    }
    httpsOnly: true
  }
}

resource eventViewerAppServiceDeploy 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: eventViewerAppService
  name: 'web'
  properties: {
    repoUrl: viewerRepoUrl
    branch: 'main'
    isManualIntegration: true
  }
}

//-------------------------------------------------------------
// EventGrid Event Viewer Subscription
//-------------------------------------------------------------
var eventViewerSubName=toLower('${environmentName}-eventviewersub')

resource eventGridTopic 'Microsoft.EventGrid/systemTopics@2023-06-01-preview' existing = {
  name: eventGridTopicName
}

resource eventViewerSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-06-01-preview' = {
  name: eventViewerSubName
  parent: eventGridTopic
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: 'https://${eventViewerAppService.properties.defaultHostName}/api/updates' 
      }
    }
    filter:{
      includedEventTypes: [
        'Microsoft.Storage.BlobDeleted'
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
  dependsOn:[
    eventViewerAppServiceDeploy
  ]
}

output eventGridViewerSubscriptionEndpoint string ='https://${eventViewerAppService.properties.defaultHostName}/api/updates' 
