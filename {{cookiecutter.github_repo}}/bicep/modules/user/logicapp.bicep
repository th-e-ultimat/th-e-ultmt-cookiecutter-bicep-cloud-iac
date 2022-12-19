param component string
param environmentType string
param location string
param prefix string

param logicAppsServerFarmId string
param logAnalyticsWorkspaceId string
param keyVaultName string

param b2cHelpersName string

param cosmosConnectionStringKeyName string

param cosmosMainDbName string
param cosmosUserContainerName string

var logicAppName = '${prefix}-la-${component}-${environmentType}'
var storageAccountName = '${prefix}lasa${component}${environmentType}'

var applicationInsightsName = '${prefix}-appi-${component}-la-${environmentType}'


var tags = {
  component: component
  environment: environmentType
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource applicationInsights 'microsoft.insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: {
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${logicAppName}': 'Resource'
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

resource b2cHelpers 'Microsoft.Web/sites@2021-03-01' existing = {
  name: b2cHelpersName
  scope: resourceGroup()
}

var b2cHelpersDefaultHostKey = listkeys('${b2cHelpers.id}/host/default', '2021-01-15').functionKeys.default

resource logicApp 'Microsoft.Web/sites@2021-01-15' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  properties: {
    httpsOnly: true
    serverFarmId: logicAppsServerFarmId
    keyVaultReferenceIdentity: 'SystemAssigned'
    siteConfig: {
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net;AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net;AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: logicAppName
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'COSMOSDB_CONNECTIONSTRING'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${cosmosConnectionStringKeyName}/)'
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
          name: 'LINK_FRESHWORKS_FUNCTION_ID'
          value: '${b2cHelpers.id}/functions/LinkFreshworks'
        }
        {
          name: 'LINK_FRESHWORKS_FUNCTION_KEY'
          value: b2cHelpersDefaultHostKey
        }
        {
          name: 'LINK_FRESHWORKS_TRIGGER_URL'
          value: uri('https://${b2cHelpers.properties.defaultHostName}','/api/user/link-freshworks') 
        }
      ]
      connectionStrings: [
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
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
        objectId: logicApp.identity.principalId
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

output logicAppId string = logicApp.id
output logicAppPrincipalIdId string = logicApp.identity.principalId
