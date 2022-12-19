targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string
param cmsKeyVaultName string
param cmsResourceGroupName string
param umbracoApiKeySecretName string
param umbracoProjectAlias string
param functionAppServerFarmId string
param logAnalyticsWorkspaceId string


var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

module dalModule 'dal.bicep' = {
  name: 'article-dal'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    functionAppServerFarmId: functionAppServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    cmsKeyVaultName: cmsKeyVaultName
    umbracoApiKeySecretName: umbracoApiKeySecretName
    umbracoProjectAlias: umbracoProjectAlias
  }
}

module cmsKvModule 'cmskv.bicep' = {
  name: 'article-cmskv'
  scope: resourceGroup(cmsResourceGroupName)
  params: {
    cmsKeyVaultName: cmsKeyVaultName
    dalPrincipalId: dalModule.outputs.dalPrincipalId
  }
  dependsOn: [
    dalModule
  ]
}

output dalId string = dalModule.outputs.dalResourceId
