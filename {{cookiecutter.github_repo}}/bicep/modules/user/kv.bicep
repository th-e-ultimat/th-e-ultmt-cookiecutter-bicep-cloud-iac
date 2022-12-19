param component string
param environmentType string
param location string
param prefix string

@secure()
param cosmosConnectionString string

@secure()
param freshsalesAPIKey string

@secure()
param freshserviceAPIKey string

@secure()
param goodWeUsername string

@secure()
param goodWePassword string

@secure()
param googleMapsAPIKey string

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
var freshsalesAPIKeyKey = 'freshsales-api-key'
var freshserviceAPIKeyKey = 'freshservice-api-key'
var goodWeUsernameKey = 'goodwe-username'
var goodWePasswordKey = 'goodwe-password'
var googleMapsAPIKeyKey = 'google-maps-api-key'

var secretsSourceDestMap = [
  {
    key: cosmosConnectionStringKey
    value: cosmosConnectionString
  }
  {
    key: freshsalesAPIKeyKey
    value: freshsalesAPIKey
  }
  {
    key: freshserviceAPIKeyKey
    value: freshserviceAPIKey
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
    key: googleMapsAPIKeyKey
    value: googleMapsAPIKey
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
output freshsalesAPIKeyName string = freshsalesAPIKeyKey
output freshserviceAPIKeyName string = freshserviceAPIKeyKey
output goodWeUserName string = goodWeUsernameKey
output goodWePassName string = goodWePasswordKey
output googleMapsAPIKeyName string = googleMapsAPIKeyKey

output keyVaultName string = keyVault.name
