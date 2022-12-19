targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

param managementRgName string
param managementKvName string

param functionAppServerFarmId string
param logicAppsServerFarmId string
param logAnalyticsWorkspaceId string

@secure()
param cosmosPrimaryConnectionString string
param cosmosMainDbName string
param cosmosUserContainerName string
param cosmosDeviceContainerName string

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

var freshsalesAPIKeySourceKey = 'freshsales-api-key'
var freshserviceAPIKeySourceKey = 'freshservice-api-key'
var goodWeUsernameSourceKey =  'goodwe-username'
var goodWePasswordSourceKey =  'goodwe-password'
var googleMapsSourceKey = 'google-maps-api-key'

module keyVaultModule 'kv.bicep' = {
  name: 'user-kv'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    cosmosConnectionString: cosmosPrimaryConnectionString
    freshsalesAPIKey: managementKeyVault.getSecret(freshsalesAPIKeySourceKey)
    freshserviceAPIKey: managementKeyVault.getSecret(freshserviceAPIKeySourceKey)
    goodWeUsername: managementKeyVault.getSecret(goodWeUsernameSourceKey)
    goodWePassword: managementKeyVault.getSecret(goodWePasswordSourceKey)
    googleMapsAPIKey: managementKeyVault.getSecret(googleMapsSourceKey)
  }
}

module dalModule 'dal.bicep' = {
  name: 'user-dal'
  scope: rg
  params: {
    goodWeUsername: keyVaultModule.outputs.goodWeUserName
    goodWePassword: keyVaultModule.outputs.goodWePassName
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    functionAppServerFarmId: functionAppServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    cosmosConnectionStringKeyName: keyVaultModule.outputs.cosmosConnectionStringKeyName

    cosmosMainDbName: cosmosMainDbName
    cosmosUserContainerName: cosmosUserContainerName
  }
  dependsOn: [
    keyVaultModule
  ]
}

module b2cModule 'b2c.bicep' = {
  name: 'user-b2c'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    functionAppServerFarmId: functionAppServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    cosmosConnectionStringKeyName: keyVaultModule.outputs.cosmosConnectionStringKeyName
    freshsalesAPIKeyName: keyVaultModule.outputs.freshsalesAPIKeyName
    freshserviceAPIKeyName: keyVaultModule.outputs.freshserviceAPIKeyName
    goodWeUserName: keyVaultModule.outputs.goodWeUserName
    goodWePassName: keyVaultModule.outputs.goodWePassName
    googleMapsAPIKeyName: keyVaultModule.outputs.googleMapsAPIKeyName
    cosmosMainDbName: cosmosMainDbName
    cosmosUserContainerName: cosmosUserContainerName
    cosmosDeviceContainerName: cosmosDeviceContainerName
  }
}

module logicAppModule 'logicapp.bicep' = {
  name: 'user-logicapp'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logicAppsServerFarmId: logicAppsServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    b2cHelpersName: b2cModule.outputs.faName
    cosmosConnectionStringKeyName: keyVaultModule.outputs.cosmosConnectionStringKeyName
    cosmosMainDbName: cosmosMainDbName
    cosmosUserContainerName: cosmosUserContainerName
  }
  dependsOn: [
    keyVaultModule
    b2cModule
  ]
}

output dalId string = dalModule.outputs.dalResourceId
output b2cId string = b2cModule.outputs.b2cResourceId
output b2cName string = b2cModule.outputs.b2cName
output b2cHelpersId string = b2cModule.outputs.faResourceId
output logicAppId string = logicAppModule.outputs.logicAppId
