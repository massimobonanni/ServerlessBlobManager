metadata description = 'Creates the Event Grid system topic for the storage account to manage.'

@description('The name of the Event Grid system topic.')
param name string

@description('The location where you want to create the resources.')
param location string = resourceGroup().location

@description('Tags applied to every resource created by this module.')
param tags object = {}

@description('The resource id of the storage account to monitor.')
param storageAccountId string

// The BlobDeleted subscription targeting the function is created by the azd postdeploy hook,
// because an Azure Function endpoint must already exist when the subscription is created.
resource systemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    source: storageAccountId
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

output name string = systemTopic.name
output id string = systemTopic.id
