param component string
param apiManagementName string

param displayName string
param description string
param versionNumber int = 1

param functionAppName string
param functionAppResourceGroupName string

param openApiJsonDefinitionPath string

param tags array

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
  scope: resourceGroup(functionAppResourceGroupName)
}

var functionAppHostName = 'https://${functionApp.properties.defaultHostName}'
var openApiJsonDefinitionUrl = uri(functionAppHostName, openApiJsonDefinitionPath)

var functionAppKey = listkeys('${functionApp.id}/host/default', '2021-01-15').functionKeys.default

var apiVersion = 'v${versionNumber}'
var uniqueName = '${toLower(replace(replace(displayName, '-', '_'), ' ', '-'))}-${apiVersion}'
var uniqueId = uniqueString(uniqueName)

resource apiManagement 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementName
}

var functionAppKeyNamedValueName = '${functionAppName}-key'
resource functionAppKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  parent: apiManagement
  name: functionAppKeyNamedValueName
  properties: {
    displayName: functionAppKeyNamedValueName
    secret: true
    value: functionAppKey
    tags: [
      'function'
      'key'
      'auto'
    ]
  }
}

resource apiManagementBackend 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  parent: apiManagement
  name: functionAppName
  properties: {
    description: '${description} Backend'
    url: uri(functionAppHostName,'api')
    protocol: 'http'
    resourceId: uri(environment().resourceManager, functionApp.id)
    credentials: {
      header: {
        'x-functions-key': [
          '{{${functionAppKeyNamedValueName}}}'
        ]
      }
    }
  }
  dependsOn: [
    functionAppKeyNamedValue
  ]
}

resource apiVersionSets 'Microsoft.ApiManagement/service/apiVersionSets@2021-08-01' = {
  parent: apiManagement
  name: uniqueId
  properties: {
    displayName: '${displayName} API'
    versioningScheme: 'Segment'
  }
}

resource apiManagementApi 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  parent: apiManagement
  name: '{{cookiecutter.git_repo_pref}}-${component}-${apiVersion}'
  properties: {
    displayName: '${displayName} API'
    description: description
    subscriptionRequired: true
    path: component
    protocols: [
      'https'
    ]
    apiType: 'http'
    isCurrent: true
    apiVersion: apiVersion
    apiVersionSetId: apiVersionSets.id
    format: 'swagger-link-json'
    value: openApiJsonDefinitionUrl
    subscriptionKeyParameterNames: {
      header: 'Wetility-Subscription-Key'
      query: '{{cookiecutter.git_repo_pref}}-subscription-key'
    }
  }
}

resource apiManagementApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  name: 'policy'
  parent: apiManagementApi
  properties: {
    format: 'xml'
    value: '<policies><inbound><base /><set-backend-service id="apim-generated-policy" backend-id="${functionAppName}" /><cors><allowed-origins><origin>*</origin></allowed-origins><allowed-methods preflight-result-max-age="300"><method>*</method></allowed-methods><allowed-headers><header>*</header></allowed-headers><expose-headers><header>*</header></expose-headers></cors></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
  }
}

// reference existing unlimited product
resource apiManagementProductUnlimited 'Microsoft.ApiManagement/service/products@2021-08-01' existing = {
  name: 'Unlimited'
  parent: apiManagement
}

// assign unlimited product
resource unlimitedProductAssignment 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  name: apiManagementApi.name
  parent: apiManagementProductUnlimited
}

// create product for just accessing this API
resource singleApiProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  parent: apiManagement
  name: '${component}-api'
  properties: {
    displayName: displayName
    description: 'Subscribers have completely unlimited access to ${displayName} API. Administrator approval is required.'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource developerGroupAssignment 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = {
  name: 'developers'
  parent: singleApiProduct
}

resource guestsGroupAssignment 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = {
  name: 'guests'
  parent: singleApiProduct
}

resource singleProductAssignment 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  name: apiManagementApi.name
  parent: singleApiProduct
}

resource apiManagementTags 'Microsoft.ApiManagement/service/tags@2021-08-01' = [for tag in tags: {
  parent: apiManagement
  name: replace(tag, ' ', '-')
  properties: {
    displayName: tag // deployment fails without this
  }
}]

resource apiTags 'Microsoft.ApiManagement/service/apis/tags@2021-08-01' = [for tag in tags: {
  parent: apiManagementApi
  name: replace(tag, ' ', '-')
  dependsOn: [
    apiManagementTags
  ]
}]
