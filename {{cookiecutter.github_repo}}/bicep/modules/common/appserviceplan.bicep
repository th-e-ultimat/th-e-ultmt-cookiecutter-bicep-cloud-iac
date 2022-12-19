param component string
param environmentType string
param location string
param prefix string

var tags = {
  component: component
  environment: environmentType
}

resource appServicePlanFunctionApp 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${prefix}-plan-${component}-func-${environmentType}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource appServicePlanLogicApp 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${prefix}-plan-${component}-la-${environmentType}'
  location: location
  tags: tags
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
    capacity: 1
  }
  kind: 'elastic'
  properties: {
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 20
  }
}

resource appServicePlanLinux 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${prefix}-plan-${component}-linux-${environmentType}'
  location: location
  kind: 'linux'
  tags: tags
  properties:{
    reserved: true
  }
  sku:{
    name: 'S1'
    tier: 'Standard'
  }
}

output functionAppServerFarmId string = appServicePlanFunctionApp.id
output logicAppServerFarmId string = appServicePlanLogicApp.id
output linuxAppServerFarmId string = appServicePlanLinux.id
