
targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

param sharedCommonRgName string
param sharedServiceBusName string

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

module serviceBusQueueModule 'servicebusqueue.bicep' = {
  name: 'device-servicebusqueue-${environmentType}'
  scope: resourceGroup(sharedCommonRgName) // queues exist in the same scope as the service bus (which is a shared one)
  params: {
    prefix: prefix
    component: component
    serviceBusName: sharedServiceBusName
  }
}

module keyVaultModule 'kv.bicep' = {
  name: 'device-kv-${environmentType}'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    qaGoodWeDataForwardingQueueListenConnectionString: serviceBusQueueModule.outputs.qaQueueListenConnectionString
    qaGoodWeDataForwardingQueueSendConnectionString: serviceBusQueueModule.outputs.qaQueueSendConnectionString
    prodGoodWeDataForwardingQueueListenConnectionString: serviceBusQueueModule.outputs.prodQueueListenConnectionString
    prodGoodWeDataForwardingQueueSendConnectionString: serviceBusQueueModule.outputs.prodQueueSendConnectionString
  }
  dependsOn: [
    serviceBusQueueModule
  ]
}

module logicAppModule 'logicapp.bicep' = {
  name: 'device-logicapp-${environmentType}'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logicAppsServerFarmId: logicAppsServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    qaGoodWeDataForwardingQueueName: serviceBusQueueModule.outputs.qaQueueName
    prodGoodWeDataForwardingQueueName: serviceBusQueueModule.outputs.prodQueueName
    qaGoodWeDataForwardingQueueSendConnectionStringKeyName: keyVaultModule.outputs.qaGoodWeDataForwardingQueueSendConnectionStringKeyName
    prodGoodWeDataForwardingQueueSendConnectionStringKeyName: keyVaultModule.outputs.prodGoodWeDataForwardingQueueSendConnectionStringKeyName
  }
  dependsOn: [
    keyVaultModule
    serviceBusQueueModule
  ]
}

output qaQueueName string = serviceBusQueueModule.outputs.qaQueueName
output prodQueueName string = serviceBusQueueModule.outputs.prodQueueName
output qaQueueListenConnectionString string = serviceBusQueueModule.outputs.qaQueueListenConnectionString
output prodQueueListenConnectionString string = serviceBusQueueModule.outputs.prodQueueListenConnectionString

output logicAppId string = logicAppModule.outputs.logicAppId
