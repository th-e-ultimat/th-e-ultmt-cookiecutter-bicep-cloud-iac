param apiManagementName string

param financialRiskDalName string
param financialRiskDalResorceGroupName string

param calculatorDalName string
param calculatorResorceGroupName string

param productDalName string
param productResorceGroupName string

param crmDalName string
param crmResorceGroupName string

param articleDalName string
param articleResorceGroupName string

param deviceDalName string
param deviceResorceGroupName string

param userDalName string
param userResorceGroupName string

param documentDalName string
param documentResorceGroupName string

resource financialRiskDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: financialRiskDalName
  scope: resourceGroup(financialRiskDalResorceGroupName)
}

resource articleDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: articleDalName
  scope: resourceGroup(articleResorceGroupName)
}

resource deviceDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: deviceDalName
  scope: resourceGroup(deviceResorceGroupName)
}

resource userDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: userDalName
  scope: resourceGroup(userResorceGroupName)
}

resource calculatorDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: calculatorDalName
  scope: resourceGroup(calculatorResorceGroupName)
}

resource productDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: productDalName
  scope: resourceGroup(productResorceGroupName)
}

resource crmDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: crmDalName
  scope: resourceGroup(crmResorceGroupName)
}

resource documentDal 'Microsoft.Web/sites@2021-03-01' existing = {
  name: documentDalName
  scope: resourceGroup(documentResorceGroupName)
}

var functionAppApiProperties = [
  {
    component: 'financialrisk'
    displayName: 'Financial Risk'
    description: 'Financial Risk Engine'
    functionAppName: financialRiskDal.name
    functionAppResourceGroupName: financialRiskDalResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Financial Risk'
    ]
  }
  {
    component: 'Article'
    displayName: 'Article'
    description: 'Article'
    functionAppName: articleDal.name
    functionAppResourceGroupName: articleResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Article'
    ]
  }
  {
    component: 'device'
    displayName: 'Device'
    description: 'Device DAL'
    functionAppName: deviceDal.name
    functionAppResourceGroupName: deviceResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Device'
    ]
  }
  {
    component: 'user'
    displayName: 'User'
    description: 'User DAL'
    functionAppName: userDal.name
    functionAppResourceGroupName: userResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'User'
    ]
  }
  {
    component: 'calculator'
    displayName: 'Calculator'
    description: 'Rapid Calculator'
    functionAppName: calculatorDal.name
    functionAppResourceGroupName: calculatorResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Calculator'
    ]
  }
  {
    component: 'product'
    displayName: 'Product'
    description: 'Product Catalog'
    functionAppName: productDal.name
    functionAppResourceGroupName: productResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Product'
    ]
  }
  {
    component: 'crm'
    displayName: 'CRM'
    description: 'CRM / Sales'
    functionAppName: crmDal.name
    functionAppResourceGroupName: crmResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'CRM'
    ]
  }
  {
    component: 'document'
    displayName: 'Document'
    description: 'Document Management'
    functionAppName: documentDal.name
    functionAppResourceGroupName: documentResorceGroupName
    openApiJsonDefinitionPath: '/api/swagger.json'
    versionNumber: 1
    tags: [
      'Document'
    ]
  }
]

module apimModule 'api.bicep' = [for functionAppApiProperty in functionAppApiProperties: {
  name: 'api-functionapp-${functionAppApiProperty.component}'
  params: {
    apiManagementName: apiManagementName
    component: functionAppApiProperty.component
    displayName: functionAppApiProperty.displayName
    description: functionAppApiProperty.description
    functionAppName: functionAppApiProperty.functionAppName
    functionAppResourceGroupName: functionAppApiProperty.functionAppResourceGroupName
    openApiJsonDefinitionPath: functionAppApiProperty.openApiJsonDefinitionPath
    versionNumber: functionAppApiProperty.versionNumber
    tags: functionAppApiProperty.tags
  }
}]
