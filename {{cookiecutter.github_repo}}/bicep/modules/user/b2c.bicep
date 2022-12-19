param component string
param environmentType string
param location string
param prefix string

param functionAppServerFarmId string
param logAnalyticsWorkspaceId string
param keyVaultName string

param cosmosConnectionStringKeyName string
param freshsalesAPIKeyName string
param freshserviceAPIKeyName string
param goodWeUserName string
param goodWePassName string
param googleMapsAPIKeyName string

param cosmosMainDbName string
param cosmosUserContainerName string
param cosmosDeviceContainerName string

var tags = {
  component: component
  environment: environmentType
}

var storageAccountName = '${prefix}sab2c${component}${environmentType}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// TODO: find a way to deploy b2c via bicep (currently getting unauthorized/unauthenticated error) for now creating manually and using `existing` keyword
var b2cDirectoryName = '{{cookiecutter.git_repo_pref}}consumer${environmentType == 'qa'? 'qa':''}.onmicrosoft.com'
// resource b2cDirectory 'Microsoft.AzureActiveDirectory/b2cDirectories@2021-04-01' = {
//   name: b2cDirectoryName
//   location: 'Global'
//   tags: tags
//   sku: {
//     name: 'PremiumP1'
//     tier: 'A0'
//   }
//   properties: {
//   }
// }
resource b2cDirectory 'Microsoft.AzureActiveDirectory/b2cDirectories@2021-04-01' existing = {
  name: b2cDirectoryName
}


var helpersStorageAccountName = '${prefix}sab2chelpers${environmentType}'
resource helpersStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: helpersStorageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

var freshsalesBaseUrl = 'https://{{cookiecutter.git_repo_pref}}.myfreshworks.com/crm/sales/api/'
var freshserviceBaseUrl = 'https://{{cookiecutter.git_repo_pref}}.freshservice.com/api/'
var freshservicePaceAssetTypeId = '51000794792'

var functionAppName = '${prefix}-func-aadb2c-helpers-${environmentType}'
resource helper 'Microsoft.Web/sites@2021-03-01' = {
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
          name: 'FRESHSALES_BASE_URL'
          value: freshsalesBaseUrl
        }
        {
          name: 'FRESHSALES_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${freshsalesAPIKeyName}/)'
        }
        {
          name: 'FRESHSERVICE_BASE_URL'
          value: freshserviceBaseUrl
        }
        {
          name: 'FRESHSERVICE_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${freshserviceAPIKeyName}/)'
        }
        {
          name: 'FRESHSERVICE_PACE_ASSET_TYPE_ID'
          value: freshservicePaceAssetTypeId
        }
        {
          name: 'GOODWE_BASE_URL'
          value: 'http://openapi.semsportal.com'
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
          name: 'GOOGLE_MAPS_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${googleMapsAPIKeyName}/)'
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
  name: '${prefix}-appi-aadb2c-helpers-${environmentType}'
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
        objectId: helper.identity.principalId
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

output faPrincipalId string = helper.identity.principalId
output faResourceId string = helper.id
output faName string = helper.name

output b2cResourceId string = b2cDirectory.id
output b2cName string = b2cDirectory.name
