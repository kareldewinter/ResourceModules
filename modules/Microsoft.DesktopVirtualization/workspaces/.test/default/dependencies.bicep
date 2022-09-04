@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the Application Group to create.')
param applicationGroupName string

@description('Required. The name of the Host Pool to create.')
param hostPoolName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    name: managedIdentityName
    location: location
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = {
    name: hostPoolName
    location: location
    properties: {
        hostPoolType: 'Pooled'
        loadBalancerType: 'BreadthFirst'
        preferredAppGroupType: 'Desktop'
    }
}

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-07-12' = {
    name: applicationGroupName
    properties: {
        applicationGroupType: 'Desktop'
        hostPoolArmPath: hostPool.id
    }
}

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Application Group.')
output applicationGroupResourceId string = applicationGroup.id
