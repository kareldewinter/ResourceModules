@description('Conditional. The name of the parent Azure Recovery Service Vault. Required if the template is used in a standalone deployment.')
param recoveryVaultName string

@description('Required. Name of the Azure Recovery Service Vault Backup Policy.')
param name string

@description('Required. Configuration of the Azure Recovery Service Vault Backup Policy.')
param backupPolicyProperties object

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource rsv 'Microsoft.RecoveryServices/vaults@2022-04-01' existing = {
  name: recoveryVaultName
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-02-01' = {
  name: name
  parent: rsv
  properties: backupPolicyProperties
}

@description('The name of the backup policy.')
output name string = backupPolicy.name

@description('The resource ID of the backup policy.')
output resourceId string = backupPolicy.id

@description('The name of the resource group the backup policy was created in.')
output resourceGroupName string = resourceGroup().name
