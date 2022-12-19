param component string
param environmentType string
param location string
param prefix string

@secure()
param abSystem string

@secure()
param abSessionId string

@secure()
param abServiceOperation string

@secure()
param abChannel string

@secure()
param abApiKey string

@secure()
param freshSalesAPIKey string

@secure()
param sftpPasswordKey string

@secure()
param sftpUserKey string 


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

var abSystemKey = 'ab-system'
var abSessionIdKey = 'ab-session-id'
var abServiceOperationKey = 'ab-service-operation'
var abChannelKey = 'ab-channel'
var abApiKeyKey = 'ab-api-key'
var freshSalesAPIKeyKey = 'freshsales-api-key'

var sftpPasswordKeyKey = 'sftp-password'
var sftpUserKeyKey = 'sftp-username'

var secretsSourceDestMap = [
  {
    key: abSystemKey
    value: abSystem
  }
  {
    key: abSessionIdKey
    value: abSessionId
  }
  {
    key: abServiceOperationKey
    value: abServiceOperation
  }
  {
    key: abChannelKey
    value: abChannel
  }
  {
    key: abApiKeyKey
    value: abApiKey
  }
  {
    key: freshSalesAPIKeyKey
    value: freshSalesAPIKey
  }
  {
    key: sftpPasswordKeyKey
    value: sftpPasswordKey
  }
  {
    key: sftpUserKeyKey
    value: sftpUserKey
  }
]

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = [for pair in secretsSourceDestMap: {
  parent: keyVault
  name: pair.key
  properties: {
    value: pair.value
  }
}]

output abSystemKey string = abSystemKey
output abSessionIdKey string = abSessionIdKey
output abServiceOperationKey string = abServiceOperationKey
output abChannelKey string = abChannelKey
output abApiKeyKey string = abApiKeyKey
output freshSalesAPIKey string = freshSalesAPIKeyKey
output keyVaultName string = keyVault.name
output sftpPassKey string = sftpPasswordKeyKey
output sftpUserKey string = sftpUserKeyKey
