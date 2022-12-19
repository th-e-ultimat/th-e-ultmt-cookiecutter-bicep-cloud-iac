
targetScope = 'subscription'
param component string
param environmentType string
param location string
param prefix string

@secure()
param abSystem string
@secure()
param abSessionId string
@secure()
param abServiceOperation string
@secure()
param abChannel string
@secure()
param abApiKey string
@secure()
param freshSalesAPIKey string

@secure()
param sftpPasswordKey string
param sftpUserKey string = 'sftp'

param managementRgName string
param managementKvName string

param logAnalyticsWorkspaceId string
param logicAppsServerFarmId string

var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

resource managementKeyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: managementKvName
  scope: resourceGroup(managementRgName)
}



module keyVaultModule 'kv.bicep' = {
  name: '${component}-kv'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    abSystem: managementKeyVault.getSecret(abSystem)
    abSessionId: managementKeyVault.getSecret(abSessionId)
    abServiceOperation: managementKeyVault.getSecret(abServiceOperation)
    abChannel: managementKeyVault.getSecret(abChannel)
    abApiKey: managementKeyVault.getSecret(abApiKey)
    freshSalesAPIKey: managementKeyVault.getSecret(freshSalesAPIKey)
    sftpPasswordKey: managementKeyVault.getSecret(sftpPasswordKey)
    sftpUserKey: managementKeyVault.getSecret(sftpUserKey)
  }
  dependsOn: [
    managementKeyVault
  ]
}

module logicAppModule 'logicapp.bicep' = {
  name: '${component}-logicapp'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logicAppsServerFarmId: logicAppsServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    abSystem: keyVaultModule.outputs.abSystemKey
    abSessionId: keyVaultModule.outputs.abSessionIdKey
    abServiceOperation: keyVaultModule.outputs.abServiceOperationKey
    abChannel: keyVaultModule.outputs.abChannelKey
    abApiKey: keyVaultModule.outputs.abApiKeyKey
    freshSalesAPIKey : keyVaultModule.outputs.freshSalesAPIKey
  }
  dependsOn: [
    keyVaultModule
  ]
}

module sftpModule 'sftp.bicep' = {
  name: '${component}-sftp'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    sftpUser : keyVaultModule.outputs.sftpUserKey
    sftpPassword: keyVaultModule.outputs.sftpPassKey
  }
  dependsOn: [
    keyVaultModule
  ]
}

output dalResourceGroupName string = rg.name
output logicAppId string = logicAppModule.outputs.logicAppId
output sftpContainerDNSLabel string = sftpModule.outputs.sftpContainerDNSLabel
