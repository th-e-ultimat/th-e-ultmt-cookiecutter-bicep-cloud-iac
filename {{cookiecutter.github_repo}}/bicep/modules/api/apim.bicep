param component string
param environmentType string
param location string
param prefix string
param logAnalyticsWorkspaceId string

var tags = {
  component: component
  environment: environmentType
}

var sku = environmentType == 'qa' ? {
  name: 'Developer'
  capacity: 1
} : {
  name: 'Basic'
  capacity: 1
}

var publisherName = environmentType == 'qa' ? 'Wetility QA' : 'Wetility'
var customHostName = environmentType == 'qa' ? '{{cookiecutter.org_second_name}}-api-qa.{{cookiecutter.git_repo_pref}}.energy' : '{{cookiecutter.org_second_name}}-api.{{cookiecutter.git_repo_pref}}.energy'

resource apiManagement 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: '${prefix}-apim-${component}-${environmentType}'
  tags: tags
  location: location
  sku: sku
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'devops@{{cookiecutter.git_repo_pref}}.energy'
    publisherName: publisherName
    hostnameConfigurations: environmentType == 'qa' ? [
      {
        hostName: customHostName
        type: 'Proxy'
        certificateSource: 'Managed'
        defaultSslBinding: true
      }
    ] : []
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${prefix}-appi-${component}-${environmentType}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource apiManagementLoggerCredentialsNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  parent: apiManagement
  name: 'logger-credentials'
  properties: {
    displayName: 'logger-credentials'
    secret: true
    value: applicationInsights.properties.InstrumentationKey
  }
}

resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  parent: apiManagement
  name: applicationInsights.name
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: '{{logger-credentials}}'
    }
    isBuffered: true
    resourceId: applicationInsights.id
  }
  dependsOn: [
    apiManagementLoggerCredentialsNamedValue
  ]
}

resource apiManagementDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2021-04-01-preview' = {
  parent: apiManagement
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'Legacy'
    logClientIp: true
    loggerId: apiManagementLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
}

resource apiManagementDiagnosticsLogger 'Microsoft.ApiManagement/service/diagnostics/loggers@2018-01-01' = {
  parent: apiManagementDiagnostics
  name: applicationInsights.name
}

output apiManagementName string = apiManagement.name
