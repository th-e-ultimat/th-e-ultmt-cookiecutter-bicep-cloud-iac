
param prefix string
param component string
param serviceBusName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusName
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: '${prefix}-set-soc-message-queue'
  parent: serviceBus
  properties: {
    requiresDuplicateDetection: true
    deadLetteringOnMessageExpiration: true
    status: 'Active'
  }
}

resource queueSendAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-send'
  parent: queue
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource queueListenAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-listen'
  parent: queue
  properties: {
    rights: [
      'Listen'
    ]
  }
}

var queueSendConnectionString = listKeys(queueSendAuthRule.id, queueSendAuthRule.apiVersion).primaryConnectionString
var queueListenConnectionString = listKeys(queueListenAuthRule.id, queueListenAuthRule.apiVersion).primaryConnectionString

output queueName string = queue.name
output queueSendConnectionString string = queueSendConnectionString
output queueListenConnectionString string = queueListenConnectionString
