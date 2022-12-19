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

module serviceBusModule 'servicebus.bicep' = {
  name: 'common-servicebus-${environmentType}'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

output rgName string = rg.name
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusId string = serviceBusModule.outputs.serviceBusId
