param prefix string
param component string
param serviceBusName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusName
}

resource qaQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: '${prefix}-goodwe-dataforward-queue-qa'
  parent: serviceBus
  properties: {
    deadLetteringOnMessageExpiration: true
    status: 'Active'
  }
}

resource prodQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: '${prefix}-goodwe-dataforward-queue-prod'
  parent: serviceBus
  properties: {
    deadLetteringOnMessageExpiration: true
    status: 'Active'
  }
}

resource qaQueueSendAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-send-qa'
  parent: qaQueue
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource prodQueueSendAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-send-prod'
  parent: prodQueue
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource qaQueueListenAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-listen-qa'
  parent: qaQueue
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource prodQueueListenAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: '${prefix}-${component}-access-key-listen-prod'
  parent: prodQueue
  properties: {
    rights: [
      'Listen'
    ]
  }
}

var qaQueueSendConnectionString = listKeys(qaQueueSendAuthRule.id, qaQueueSendAuthRule.apiVersion).primaryConnectionString
var qaQueueListenConnectionString = listKeys(qaQueueListenAuthRule.id, qaQueueListenAuthRule.apiVersion).primaryConnectionString

var prodQueueSendConnectionString = listKeys(prodQueueSendAuthRule.id, prodQueueSendAuthRule.apiVersion).primaryConnectionString
var prodQueueListenConnectionString = listKeys(prodQueueListenAuthRule.id, prodQueueListenAuthRule.apiVersion).primaryConnectionString

output qaQueueName string = qaQueue.name
output prodQueueName string = prodQueue.name
output qaQueueSendConnectionString string = qaQueueSendConnectionString
output qaQueueListenConnectionString string = qaQueueListenConnectionString
output prodQueueSendConnectionString string = prodQueueSendConnectionString
output prodQueueListenConnectionString string = prodQueueListenConnectionString
