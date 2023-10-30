@description('The location wher you want to create the resources.')
param location string = resourceGroup().location

@description('The name of the environment. It will be used to create the name of the resources in the resource group.')
@maxLength(16)
@minLength(3)
param environmentName string = 'sbm${uniqueString(subscription().id, resourceGroup().name)}'

var storageAccountName = toLower('${environmentName}dstore')
var functionAppStorageAccountName = toLower('${environmentName}appstore')
var funcHostingPlanName = toLower('${environmentName}-plan')
var functionAppName = toLower('${environmentName}-func')
var applicationInsightsName = toLower('${environmentName}-ai')
var eventGridTopicName = toLower('${environmentName}-topic')
var eventGridSubName = toLower('${environmentName}-blobdeleted-sub')

//-------------------------------------------------------------
// The storage accpunt to manage
//-------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' ={
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  parent: blobService
  name: 'documents'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}
//-------------------------------------------------------------

//-------------------------------------------------------------
// The Azure function App used to manage the storage
//-------------------------------------------------------------
resource functionAppStorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: functionAppStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource funcHostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: funcHostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: funcHostingPlan.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionAppStorageAccount.listKeys().keys[0].value}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionAppStorageAccount.listKeys().keys[0].value}'
    WEBSITE_CONTENTSHARE: toLower(functionAppName)
    FUNCTIONS_EXTENSION_VERSION: '~4'
    WEBSITE_NODE_DEFAULT_VERSION: '~10'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    UseManagedIdentity : true
    StorageAccountName:storageAccountName
    StorageAccessKey:''
  }
}
//-------------------------------------------------------------


//-------------------------------------------------------------
// Event Grid topic to capture the BlodDeleted event from storage
//-------------------------------------------------------------
resource eventGridTopic 'Microsoft.EventGrid/systemTopics@2023-06-01-preview' = {
  name: eventGridTopicName
  location: location
  properties: {
    source: storageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource eventGridSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-06-01-preview' = {
  parent: eventGridTopic
  name: eventGridSubName
  properties: {
    destination: {
      endpointType:'AzureFunction'
      properties: {
        resourceId: functionApp.id
        maxEventsPerBatch: 1
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobDeleted'
      ]
    }
  }
}

output eventGridTopicName string = eventGridTopic.name
