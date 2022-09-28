targetScope = 'subscription'

param managedIdentityResourceId string
param managedIdentityPrincipalId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'Contributor', managedIdentityResourceId)
  // name: guid(subscription().subscriptionId, 'Contributor', managedIdentityName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
