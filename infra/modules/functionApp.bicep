metadata description = 'Creates the function app, its hosting plan, its runtime storage account and Application Insights.'

@description('The name of the function app.')
param name string

@description('The location where you want to create the resources.')
param location string = resourceGroup().location

@description('Tags applied to every resource created by this module.')
param tags object = {}

@description('The name of the AZD service mapped to this function app.')
param serviceName string = 'func'

@description('The name of the app service plan hosting the function app.')
param hostingPlanName string

@description('The name of the storage account used by the function app runtime.')
@minLength(3)
@maxLength(24)
param functionStorageAccountName string

@description('The name of the Application Insights instance used by the function app.')
param applicationInsightsName string

@description('The name of the storage account managed by the function app.')
param managedStorageAccountName string

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: functionStorageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': serviceName })
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
    }
    httpsOnly: true
  }
}

resource basicCredentialPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: functionApp
  name: 'scm'
  properties: {
    allow: true
  }
}

var functionStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'

resource appSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    AzureWebJobsStorage: functionStorageConnectionString
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: functionStorageConnectionString
    WEBSITE_CONTENTSHARE: toLower(name)
    WEBSITE_RUN_FROM_PACKAGE: '1'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    ServicePrincipalClientId: ''
    ServicePrincipalClientSecret: ''
    ServicePrincipalTenantId: ''
  }
}

output name string = functionApp.name
output id string = functionApp.id
output principalId string = functionApp.identity.principalId
output uri string = 'https://${functionApp.properties.defaultHostName}'
output applicationInsightsName string = applicationInsights.name
