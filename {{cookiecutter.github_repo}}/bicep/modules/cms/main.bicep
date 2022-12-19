targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string
param managementRgName string
param managementKvName string

var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

resource managementKeyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: managementKvName
  scope: resourceGroup(managementRgName)
}

var umbracoApiKeySourceKey = environmentType == 'qa' ? 'umbraco-api-key-dev' : 'umbraco-api-key'

module keyVaultModule 'kv.bicep' = {
  name: 'cms-kv'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    umbracoApiKey: managementKeyVault.getSecret(umbracoApiKeySourceKey)
  }
}

var umbracoHeartcoreProjectAlias = environmentType == 'qa' ? 'dev-{{cookiecutter.org_second_name}}' : '{{cookiecutter.org_second_name}}'

output keyVaultName string = keyVaultModule.outputs.keyVaultName
output resourceGroupName string = rg.name
output umbracoApiKeyName string = keyVaultModule.outputs.umbracoApiKeyName
output umbracoProjectAlias string = umbracoHeartcoreProjectAlias
 