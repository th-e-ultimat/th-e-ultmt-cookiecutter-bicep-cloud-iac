param component string
param environmentType string
param location string
param prefix string

var tags = {
  component: component
  environment: environmentType
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: '${prefix}-sb-${component}-${environmentType}'
  location: location
  tags: tags
  sku: {
    capacity: 1
    name: 'Standard'
    tier: 'Standard'
  }
}

output serviceBusName string = serviceBus.name
output serviceBusId string = serviceBus.id
