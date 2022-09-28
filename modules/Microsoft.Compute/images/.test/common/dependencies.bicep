@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the Storage Account to create.')
param storageAccountName string

@description('Required. The name prefix of the Image Template to create.')
param imageTemplateNamePrefix string

@description('Generated. Do not provide a value! This date value is used to generate a unique image template name.')
param baseTime string = utcNow('yyyy-MM-dd-HH-mm-ss')

@description('Required. The name of the Deployment Script to create for triggering the image creation.')
param triggerImageDeploymentScriptName string

@description('Required. The name of the Deployment Script to copy the VHD to a destination storage account.')
param copyVhdDeploymentScriptName string

@description('Required. The name of the destination Storage Account to copy the created VHD to.')
param destinationStorageAccountName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
  }
  resource blobServices 'blobServices@2021-09-01' = {
    name: 'default'
    resource container 'containers@2021-09-01' = {
      name: 'vhds'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

module roleAssignment 'dependencies_rbac.bicep' = {
  name: '${uniqueString(deployment().name, location)}-MSI-roleAssignment'
  scope: subscription()
  params: {
    managedIdentityPrincipalId: managedIdentity.properties.principalId
    managedIdentityResourceId: managedIdentity.id
  }
}

// Deploy image template
resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: '${imageTemplateNamePrefix}-${baseTime}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 0
    vmProfile: {
      vmSize: 'Standard_D2s_v3'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-10'
      sku: '19h2-evd'
      version: 'latest'
    }
    distribute: [
      {
        type: 'VHD'
        runOutputName: '${imageTemplateNamePrefix}-VHD'
        artifactTags: {}
      }
    ]
    customize: [
      {
        restartTimeout: '30m'
        type: 'WindowsRestart'
      }
    ]
  }
}

// // Trigger VHD creation
// resource triggerImageDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: triggerImageDeploymentScriptName
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${managedIdentity.id}': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '8.0'
//     retentionInterval: 'P1D'
//     arguments: '-ImageTemplateName \\"${imageTemplate.name}\\" -ImageTemplateResourceGroup \\"${resourceGroup().name}\\"'
//     scriptContent: loadTextContent('../.scripts/Start-ImageTemplate.ps1')
//     cleanupPreference: 'OnSuccess'
//     forceUpdateTag: baseTime
//   }
//   dependsOn: [
//     roleAssignment
//   ]
// }

// // Copy VHD to destination storage account
// resource copyVhdDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: copyVhdDeploymentScriptName
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${managedIdentity.id}': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '8.0'
//     retentionInterval: 'P1D'
//     arguments: '-ImageTemplateName \\"${imageTemplate.name}\\" -ImageTemplateResourceGroup \\"${resourceGroup().name}\\" -DestinationStorageAccountName \\"${destinationStorageAccountName}\\" -VhdName \\"${imageTemplateNamePrefix}\\" -WaitForComplete'
//     scriptContent: loadTextContent('../.scripts/Copy-VhdToStorageAccount.ps1')
//     cleanupPreference: 'OnSuccess'
//     forceUpdateTag: baseTime
//   }
//   dependsOn: [ triggerImageDeploymentScript ]
// }

@description('The URI of the created VHD.')
output vhdUri string = 'https://${destinationStorageAccountName}.blob.core.windows.net/vhds/${imageTemplateNamePrefix}.vhd'

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Managed Identity.')
output managedIdentityResourceId string = managedIdentity.id
