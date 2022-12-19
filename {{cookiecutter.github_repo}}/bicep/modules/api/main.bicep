targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

param logAnalyticsWorkspaceId string

var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

module apiManagementModule 'apim.bicep' = {
  name: 'api-apimanagement'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}
