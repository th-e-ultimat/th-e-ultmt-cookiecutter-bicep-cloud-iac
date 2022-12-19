targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

param sharedEnvironmentType string = 'shared'

var tags = {
  component: component
  environment: environmentType
}

module sharedModule 'shared/main.bicep' = {
  name: 'common-shared'
  params: {
    component: component
    environmentType: sharedEnvironmentType
    location: location
    prefix: prefix
  }
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

module appservicePlanModule 'appserviceplan.bicep' = {
  name: 'common-appserviceplan'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

module logAnalyticsModule 'loganalytics.bicep' = {
  name: 'common-loganalytics'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

module serviceBusModule 'servicebus.bicep' = {
  name: 'common-servicebus'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}


var appServicePlanLogicAppQaName = '${prefix}-plan-${component}-la-qa'
var appServicePlanLogicAppQaRgName = '${prefix}-rg-${component}-qa'

resource appServicePlanLogicAppQa 'Microsoft.Web/serverfarms@2021-01-15' existing = {
  name: appServicePlanLogicAppQaName
  scope: resourceGroup(appServicePlanLogicAppQaRgName)
}

output commonRgName string = rg.name
output functionAppServerFarmId string = appservicePlanModule.outputs.functionAppServerFarmId
output logicAppServerFarmId string = appservicePlanModule.outputs.logicAppServerFarmId
output linuxAppServerFarmId string = appservicePlanModule.outputs.linuxAppServerFarmId
output logAnalyticsWorkspaceId string = logAnalyticsModule.outputs.logAnalyticsWorkspaceId
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusId string = serviceBusModule.outputs.serviceBusId

output commonSharedRgName string = sharedModule.outputs.rgName
output sharedServiceBusName string = sharedModule.outputs.serviceBusName
output sharedServiceBusId string = sharedModule.outputs.serviceBusId

output sharedLogicAppServerFarmId string = appServicePlanLogicAppQa.id // use QA logic app plan as shared plan (as opposed to created a new one entirely)
