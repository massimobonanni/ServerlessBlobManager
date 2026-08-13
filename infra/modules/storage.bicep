metadata description = 'Creates the storage account managed by the Serverless Blob Manager function.'

@description('The name of the storage account to manage.')
@minLength(3)
@maxLength(24)
param name string

@description('The location where you want to create the resources.')
param location string = resourceGroup().location

@description('Tags applied to every resource created by this module.')
param tags object = {}

@description('The name of the container created in the storage account to manage.')
param containerName string = 'documents'

@description('The number of days the deleted blobs and containers are retained (soft delete).')
@minValue(1)
@maxValue(365)
param deleteRetentionDays int = 7

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: deleteRetentionDays
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: deleteRetentionDays
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

output name string = storageAccount.name
output id string = storageAccount.id
output containerName string = container.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
