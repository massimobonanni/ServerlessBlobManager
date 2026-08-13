metadata description = 'Grants the function app identity the rights needed to undelete blobs in the managed storage account.'

@description('The name of the storage account to manage where the role must be assigned.')
param storageAccountName string

@description('The principal id of the identity that undeletes the blobs.')
param principalId string

@description('The type of the principal receiving the role assignment.')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

// Storage Blob Data Contributor: required to undelete blobs in the managed storage account
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, principalId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = storageRoleAssignment.id
