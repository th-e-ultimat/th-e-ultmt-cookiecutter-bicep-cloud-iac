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
param cosmosDeviceContainerName string

param goodWeUserName string
param goodWePassName string
param umbracoApiKeyName string

param socSettingsQueueSendConnectionStringKeyName string
param socSettingsQueueName string

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

var umbracoProjectAlias = environmentType == 'qa' ? 'dev-{{cookiecutter.org_second_name}}' : '{{cookiecutter.org_second_name}}'

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
          name: 'DEVICE_CONTAINER_ID'
          value: cosmosDeviceContainerName
        }
        {
          name: 'GOODWE_BASE_URL'
          value: 'http://openapi.semsportal.com'
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
          name: 'GOODWE_USERNAME'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${goodWeUserName}/)'
        }
        {
          name: 'GOODWE_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${goodWePassName}/)'
        }
        {
          name: 'UMBRACO_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${umbracoApiKeyName}/)'
        }
        {
          name: 'SERVICE_BUS_CONNECTION'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${socSettingsQueueSendConnectionStringKeyName}/)'
        }
        {
          name: 'SOC_SETTINGS_QUEUE_NAME'
          value: socSettingsQueueName
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

output dalResourceId string = dal.id
output dalName string = dal.name
