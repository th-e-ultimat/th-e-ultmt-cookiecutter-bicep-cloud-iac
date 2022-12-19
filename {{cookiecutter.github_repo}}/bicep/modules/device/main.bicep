targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string
param commonRgName string
param serviceBusName string
param sharedEnvironmentType string = 'shared'

param managementRgName string
param managementKvName string

param functionAppServerFarmId string
param logAnalyticsWorkspaceId string

@secure()
param cosmosPrimaryConnectionString string
param cosmosMainDbName string
param cosmosDeviceContainerName string
param cosmosUserContainerName string

param logicAppsServerFarmId string

param sharedLogicAppServerFarmId string

param sharedCommonRgName string
param sharedServiceBusName string

var tags = {
  component: component
  environment: environmentType
}

module sharedModule 'shared/main.bicep' = {
  name: 'device-shared'
  params: {
    component: component
    environmentType: sharedEnvironmentType
    location: location
    prefix: prefix
    sharedCommonRgName: sharedCommonRgName
    sharedServiceBusName: sharedServiceBusName
    logicAppsServerFarmId: sharedLogicAppServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
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

var goodWeUsernameSourceKey = 'goodwe-username'
var goodWePasswordSourceKey = 'goodwe-password'
var umbracoApiKeySourceKey = environmentType == 'qa' ? 'umbraco-api-key-dev' : 'umbraco-api-key'

var goodWeDataForwardingQueueListenConnectionString = environmentType == 'qa' ? sharedModule.outputs.qaQueueListenConnectionString : sharedModule.outputs.prodQueueListenConnectionString

module serviceBusQueueModule 'servicebusqueue.bicep' = {
  name: 'device-servicebus-queue'
  scope: resourceGroup(commonRgName) // queues exist in the same scope as the service bus (which is a shared one)
  params: {
    prefix: prefix
    component: component
    serviceBusName: serviceBusName
  }
}

module keyVaultModule 'kv.bicep' = {
  name: 'device-kv'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    cosmosConnectionString: cosmosPrimaryConnectionString
    goodWeUsername: managementKeyVault.getSecret(goodWeUsernameSourceKey)
    goodWePassword: managementKeyVault.getSecret(goodWePasswordSourceKey)
    umbracoApiKey: managementKeyVault.getSecret(umbracoApiKeySourceKey)
    goodWeDataForwardingQueueListenConnectionString: goodWeDataForwardingQueueListenConnectionString
    socSettingsQueueSendConnectionString: serviceBusQueueModule.outputs.queueSendConnectionString
    socSettingsQueueListenConnectionString: serviceBusQueueModule.outputs.queueListenConnectionString
  }
  dependsOn: [
    serviceBusQueueModule
  ]
}

module dalModule 'dal.bicep' = {
  name: 'device-dal'
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
    cosmosMainDbName: cosmosMainDbName
    cosmosDeviceContainerName: cosmosDeviceContainerName
    cosmosUserContainerName: cosmosUserContainerName
    goodWeUserName: keyVaultModule.outputs.goodWeUserName
    goodWePassName: keyVaultModule.outputs.goodWePassName
    socSettingsQueueSendConnectionStringKeyName: keyVaultModule.outputs.socSettingsQueueSendConnectionStringKeyName
    socSettingsQueueName: serviceBusQueueModule.outputs.queueName
    umbracoApiKeyName: keyVaultModule.outputs.umbracoApiKeyName
  }
  dependsOn: [
    keyVaultModule
  ]
}

var goodWeDataForwardingQueueName = environmentType == 'qa' ? sharedModule.outputs.qaQueueName : sharedModule.outputs.prodQueueName

module logicAppModule 'logicapp.bicep' = {
  name: 'device-logicapp'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logicAppsServerFarmId: logicAppsServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    cosmosConnectionStringKeyName: keyVaultModule.outputs.cosmosConnectionStringKeyName
    cosmosMainDbName: cosmosMainDbName
    cosmosDeviceContainerName: cosmosUserContainerName
    goodWeDataForwardingQueueName: goodWeDataForwardingQueueName
    goodWeDataForwardingQueueListenConnectionStringKeyName: keyVaultModule.outputs.goodWeDataForwardingQueueListenConnectionStringKeyName
  }
  dependsOn: [
    keyVaultModule
  ]
}

output dalId string = dalModule.outputs.dalResourceId
output dalName string = dalModule.outputs.dalName
output dalResourceGroupName string = rg.name
output logicAppId string = logicAppModule.outputs.logicAppId
output sharedLogicAppId string = sharedModule.outputs.logicAppId
