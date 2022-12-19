targetScope = 'subscription'

param component string
param environmentType string
param location string
param prefix string

param managementRgName string
param managementKvName string

param logicAppServerFarmId string
param logAnalyticsWorkspaceId string
param linuxAppServerFarmId string

var tags = {
  component: component
  environment: environmentType
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-${component}-${environmentType}'
  location: location
  tags: tags
}

resource managementKeyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: managementKvName
  scope: resourceGroup(managementRgName)
}

var dbAdminPasswordSourceKey = environmentType == 'qa' ? 'snowflake-db-password-qa' : 'snowflake-db-password'
var dbAdminLogin = 'snowflake_admin'
module dbModule 'db.bicep' = {
  name: 'snowflake-db'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    adminLogin: dbAdminLogin
    adminPassword: managementKeyVault.getSecret(dbAdminPasswordSourceKey)
  }
}

module appServiceModule 'appservice.bicep' = {
  name: 'snowflake-appservice'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    linuxServerFarmId: linuxAppServerFarmId
    dbServerName: dbModule.outputs.dbServerName
    dbAdminLogin: dbAdminLogin
    dbAdAdminPassword:managementKeyVault.getSecret(dbAdminPasswordSourceKey)
  }
  dependsOn: [
    dbModule
  ]
}

module logicAppModule 'logicapp.bicep' = {
  name: 'snowflake-logicapp'
  scope: rg
  params: {
    component: component
    environmentType: environmentType
    location: location
    prefix: prefix
    logicAppServerFarmId: logicAppServerFarmId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
  dependsOn: [
    dbModule
  ]
}

output logicAppId string = logicAppModule.outputs.laResourceId
output webAppId string = appServiceModule.outputs.webAppId
