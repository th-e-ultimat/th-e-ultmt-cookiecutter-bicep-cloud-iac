param component string
param environmentType string
param location string
param prefix string

param logicAppServerFarmId string
param logAnalyticsWorkspaceId string


var tags = {
  component: component
  environment: environmentType
}

var storageAccountName = '${prefix}sala${component}${environmentType}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

var logicAppName = '${prefix}-la-${component}-dal-${environmentType}'
resource logicApp 'Microsoft.Web/sites@2021-03-01' = {
  name: logicAppName
  location: location
  tags: tags
  kind: 'functionapp,workflowapp'
  properties: {
    httpsOnly: true
    serverFarmId: logicAppServerFarmId
    clientAffinityEnabled: true
    keyVaultReferenceIdentity: 'SystemAssigned'
    siteConfig: {
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
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource applicationInsights 'microsoft.insights/components@2020-02-02' = {
  name: '${prefix}-appi-${component}-la-${environmentType}'
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

output laResourceId string = logicApp.id
output laName string = logicApp.name
