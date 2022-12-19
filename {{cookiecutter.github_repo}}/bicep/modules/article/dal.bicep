param component string
param environmentType string
param location string
param prefix string

param functionAppServerFarmId string
param logAnalyticsWorkspaceId string
param cmsKeyVaultName string
param umbracoProjectAlias string
param umbracoApiKeySecretName string


var tags = {
  component: component
  environment: environmentType
}

var storageAccountName = '${prefix}sa${component}${environmentType}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

var functionAppName = '${prefix}-func-${component}-dal-${environmentType}'
resource dal 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: functionAppServerFarmId
    clientAffinityEnabled: true
    keyVaultReferenceIdentity: 'SystemAssigned'
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'UMBRACO_GRAPHQL_BASE_URL'
          value: 'https://graphql.umbraco.io'
        }
        {
          name: 'UMBRACO_PROJECT_ALIAS'
          value: umbracoProjectAlias
        }
        {
          name: 'UMBRACO_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${cmsKeyVaultName}.vault.azure.net/secrets/${umbracoApiKeySecretName}/)'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource applicationInsights 'microsoft.insights/components@2020-02-02' = {
  name: '${prefix}-appi-${component}-dal-${environmentType}'
  location: location
  tags: {
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionAppName}': 'Resource'
    component: tags.component
    environment: tags.environment
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output dalPrincipalId string = dal.identity.principalId
output dalResourceId string = dal.id
output dalName string = dal.name
