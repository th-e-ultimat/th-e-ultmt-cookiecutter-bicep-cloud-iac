param component string
param environmentType string
param location string
param prefix string

param functionAppServerFarmId string
param logAnalyticsWorkspaceId string
param keyVaultName string


param cosmosConnectionStringKeyName string
param cosmosMainDbName string
param cosmosUserContainerName string

@secure()
param goodWeUsername string
@secure()
param goodWePassword string


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
          name: 'DATABASE_ID'
          value: cosmosMainDbName
        }
        {
          name: 'USER_CONTAINER_ID'
          value: cosmosUserContainerName
        }
        {
          name: 'GOODWE_BASE_URL'
          value: 'http://openapi.semsportal.com'
        }
        {
          name: 'GOODWE_USERNAME'
          value:'@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${goodWeUsername}/)'
        }
        {
          name: 'GOODWE_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${goodWePassword}/)'
        }
      ]
      connectionStrings: [
        {
          name: 'COSMOSDB_CONNECTIONSTRING'
          connectionString: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${cosmosConnectionStringKeyName}/)'
          type: 'Custom'
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

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: dal.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'list'
            'get'
          ]
          storage: []
        }
      }
    ]
  }
}

output dalPrincipalId string = dal.identity.principalId
output dalResourceId string = dal.id
output dalName string = dal.name
