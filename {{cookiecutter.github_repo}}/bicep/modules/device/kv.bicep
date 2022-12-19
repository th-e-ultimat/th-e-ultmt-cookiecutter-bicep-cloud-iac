param component string
param environmentType string
param location string
param prefix string

@secure()
param cosmosConnectionString string

@secure()
param goodWeUsername string

@secure()
param goodWePassword string

@secure()
param umbracoApiKey string

@secure()
param socSettingsQueueSendConnectionString string

@secure()
param socSettingsQueueListenConnectionString string

@secure()
param goodWeDataForwardingQueueListenConnectionString string

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

var cosmosConnectionStringKey = 'cosmos-db-connection-string'
var goodWeUsernameKey = 'goodwe-username'
var goodWePasswordKey = 'goodwe-password'
var umbracoApiKeyKey = 'umbraco-api-key'
var goodWeDataForwardingQueueListenConnectionStringKey = 'goodwe-dataforward-queue-listen-connection-string'
var socSettingsQueueSendConnectionStringKey = 'soc-settings-queue-send-connection-string'
var socSettingsQueueListenConnectionStringKey = 'soc-settings-queue-listen-connection-string'

var secretsSourceDestMap = [
  {
    key: cosmosConnectionStringKey
    value: cosmosConnectionString
  }
  {
    key: goodWeUsernameKey
    value: goodWeUsername
  }
  {
    key: goodWePasswordKey
    value: goodWePassword
  }
  {
    key: umbracoApiKeyKey
    value: umbracoApiKey
  }
  {
    key: goodWeDataForwardingQueueListenConnectionStringKey
    value: goodWeDataForwardingQueueListenConnectionString
  }
  {
    key: socSettingsQueueSendConnectionStringKey
    value: socSettingsQueueSendConnectionString
  }
  {
    key: socSettingsQueueListenConnectionStringKey
    value: socSettingsQueueListenConnectionString
  }
]

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = [for pair in secretsSourceDestMap: {
  parent: keyVault
  name: pair.key
  properties: {
    value: pair.value
  }
}]

output cosmosConnectionStringKeyName string = cosmosConnectionStringKey
output goodWeUserName string = goodWeUsernameKey
output goodWePassName string = goodWePasswordKey
output umbracoApiKeyName string = umbracoApiKeyKey
output goodWeDataForwardingQueueListenConnectionStringKeyName string = goodWeDataForwardingQueueListenConnectionStringKey

output socSettingsQueueSendConnectionStringKeyName string = socSettingsQueueSendConnectionStringKey
output socSettingsQueueListenConnectionStringKeyName string = socSettingsQueueListenConnectionStringKey


output keyVaultName string = keyVault.name
