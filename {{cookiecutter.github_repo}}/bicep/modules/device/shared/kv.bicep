param component string
param environmentType string
param location string
param prefix string

@secure()
param qaGoodWeDataForwardingQueueSendConnectionString string

@secure()
param qaGoodWeDataForwardingQueueListenConnectionString string

@secure()
param prodGoodWeDataForwardingQueueSendConnectionString string

@secure()
param prodGoodWeDataForwardingQueueListenConnectionString string

var tags = {
  component: component
  environment: environmentType
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: '${prefix}-kv-${component}-${environmentType}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForTemplateDeployment: true
  }
}


var qaGoodWeDataForwardingQueueSendConnectionStringKey = 'goodwe-dataforward-queue-send-connection-string-qa'
var qaGoodWeDataForwardingQueueListenConnectionStringKey = 'goodwe-dataforward-queue-listen-connection-string-qa'
var prodGoodWeDataForwardingQueueSendConnectionStringKey = 'goodwe-dataforward-queue-send-connection-string-prod'
var prodGoodWeDataForwardingQueueListenConnectionStringKey = 'goodwe-dataforward-queue-listen-connection-string-prod'


var secretsSourceDestMap = [
  {
    key: qaGoodWeDataForwardingQueueSendConnectionStringKey
    value: qaGoodWeDataForwardingQueueSendConnectionString
  }
  {
    key: qaGoodWeDataForwardingQueueListenConnectionStringKey
    value: qaGoodWeDataForwardingQueueListenConnectionString
  }
  {
    key: prodGoodWeDataForwardingQueueSendConnectionStringKey
    value: prodGoodWeDataForwardingQueueSendConnectionString
  }
  {
    key: prodGoodWeDataForwardingQueueListenConnectionStringKey
    value: prodGoodWeDataForwardingQueueListenConnectionString
  }
]


resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = [for pair in secretsSourceDestMap: {
  parent: keyVault
  name: pair.key
  properties: {
    value: pair.value
  }
}]

output qaGoodWeDataForwardingQueueSendConnectionStringKeyName string = qaGoodWeDataForwardingQueueSendConnectionStringKey
output qaGoodWeDataForwardingQueueListenConnectionStringKeyName string = qaGoodWeDataForwardingQueueListenConnectionStringKey
output prodGoodWeDataForwardingQueueSendConnectionStringKeyName string = prodGoodWeDataForwardingQueueSendConnectionStringKey
output prodGoodWeDataForwardingQueueListenConnectionStringKeyName string = prodGoodWeDataForwardingQueueListenConnectionStringKey

output keyVaultName string = keyVault.name
