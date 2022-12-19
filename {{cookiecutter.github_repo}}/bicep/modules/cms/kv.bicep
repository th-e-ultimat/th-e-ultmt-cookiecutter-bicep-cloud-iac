param component string
param environmentType string
param location string
param prefix string

@secure()
param umbracoApiKey string

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

var umbracoApiKeyKey = 'umbraco-api-key'

var secretsSourceDestMap = [
  {
    key: umbracoApiKeyKey
    value: umbracoApiKey
  }
]


resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = [for pair in secretsSourceDestMap: {
  parent: keyVault
  name: pair.key
  properties: {
    value: pair.value
  }
}]

output umbracoApiKeyName string = umbracoApiKeyKey

output keyVaultName string = keyVault.name
