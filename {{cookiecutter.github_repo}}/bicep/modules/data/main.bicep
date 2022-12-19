targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}


module cosmosModule 'cosmos.bicep' = {
  name: 'data-cosmos'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

output rgName string = rg.name
output cosmosAccountName string = cosmosModule.outputs.accountName
output cosmosMainDbName string = cosmosModule.outputs.mainDbName
output cosmosPrimaryConnectionString string = cosmosModule.outputs.primaryConnectionString
output cosmosUserContainerName string = cosmosModule.outputs.userContainerName
output cosmosDeviceContainerName string = cosmosModule.outputs.deviceContainerName
output cosmosNotificationContainerName string = cosmosModule.outputs.notificationContainerName
