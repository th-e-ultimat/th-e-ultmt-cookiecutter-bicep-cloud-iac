targetScope = 'subscription'

@allowed([
  'qa'
  'prod'
])

param environmentType string = 'qa'
param location string = 'southafricanorth'
param prefix string = '{{cookiecutter.string_prefix}}'

param managementRgName string = '{{cookiecutter.string_prefix}}-rg-management-shared'
param managementKvName string = '{{cookiecutter.string_prefix}}-kv-management-shared'


param abSystem string = 'ab-system'
param abSessionId string = 'ab-session-id'
param abServiceOperation string = 'ab-service-operation'
param abChannel string = 'ab-channel'
param abApiKey string = 'ab-api-key'
param freshSalesAPIKey string = 'freshsales-api-key'

param sftpUserKey string = 'sftp-username'
param sftpPassKey string = 'sftp-password'




module commonModule 'modules/common/main.bicep' = {
  name: 'common'
  params: {
    component: 'common'
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

module dataModule 'modules/data/main.bicep' = {
  name: 'data'
  params: {
    component: 'data'
    environmentType: environmentType
    location: location
    prefix: prefix
  }
}

module cmsModule 'modules/cms/main.bicep' = {
  name: 'cms'
  params: {
    component: 'cms'
    environmentType: environmentType
    location: location
    prefix: prefix
    managementKvName: managementKvName
    managementRgName: managementRgName
  }
}

module userModule 'modules/user/main.bicep' = {
  name: 'user'
  params: {
    component: 'user'
    environmentType: environmentType
    location: location
    prefix: prefix
    managementKvName: managementKvName
    managementRgName: managementRgName
    functionAppServerFarmId: commonModule.outputs.functionAppServerFarmId
    logicAppsServerFarmId: commonModule.outputs.logicAppServerFarmId
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
    cosmosPrimaryConnectionString: dataModule.outputs.cosmosPrimaryConnectionString
    cosmosMainDbName: dataModule.outputs.cosmosMainDbName
    cosmosUserContainerName: dataModule.outputs.cosmosUserContainerName
    cosmosDeviceContainerName: dataModule.outputs.cosmosDeviceContainerName
  }
  dependsOn: [
    commonModule
    dataModule
  ]
}

module articleModule 'modules/article/main.bicep' = {
  name: 'article'
  params: {
    component: 'article'
    environmentType: environmentType
    location: location
    prefix: prefix
    cmsKeyVaultName: cmsModule.outputs.keyVaultName
    cmsResourceGroupName: cmsModule.outputs.resourceGroupName
    umbracoApiKeySecretName: cmsModule.outputs.umbracoApiKeyName
    umbracoProjectAlias: cmsModule.outputs.umbracoProjectAlias
    functionAppServerFarmId: commonModule.outputs.functionAppServerFarmId
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    commonModule
    cmsModule
  ]
}

module deviceModule 'modules/device/main.bicep' = {
  name: 'device'
  params: {
    component: 'device'
    environmentType: environmentType
    location: location
    prefix: prefix
    managementKvName: managementKvName
    managementRgName: managementRgName
    commonRgName: commonModule.outputs.commonRgName
    serviceBusName: commonModule.outputs.serviceBusName
    functionAppServerFarmId: commonModule.outputs.functionAppServerFarmId
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
    logicAppsServerFarmId: commonModule.outputs.logicAppServerFarmId
    sharedLogicAppServerFarmId: commonModule.outputs.sharedLogicAppServerFarmId
    cosmosPrimaryConnectionString: dataModule.outputs.cosmosPrimaryConnectionString
    cosmosMainDbName: dataModule.outputs.cosmosMainDbName
    cosmosDeviceContainerName: dataModule.outputs.cosmosDeviceContainerName
    cosmosUserContainerName: dataModule.outputs.cosmosUserContainerName
    sharedCommonRgName: commonModule.outputs.commonSharedRgName
    sharedServiceBusName: commonModule.outputs.sharedServiceBusName
  }
  dependsOn: [
    commonModule
    dataModule
  ]
}

module snowflakeModule 'modules/snowflake/main.bicep' = {
  name: 'snowflake'
  params: {
    component: 'snowflake'
    environmentType: environmentType
    location: location
    prefix: prefix
    managementKvName: managementKvName
    managementRgName: managementRgName
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
    logicAppServerFarmId: commonModule.outputs.logicAppServerFarmId
    linuxAppServerFarmId: commonModule.outputs.linuxAppServerFarmId
  }
  dependsOn: [
    commonModule
  ]
}

module apiModule 'modules/api/main.bicep' = {
  name: 'api'
  params: {
    component: 'api'
    environmentType: environmentType
    location: location
    prefix: prefix
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    commonModule
  ]
}

module partnershipBankModule 'modules/partnership/main.bicep' = {
  name: 'partnership'
  params: {
    component: 'partnership'
    environmentType: environmentType
    location: location
    prefix: prefix
    managementKvName: managementKvName
    managementRgName: managementRgName
    abSystem : abSystem
    abSessionId : abSessionId 
    abServiceOperation: abServiceOperation
    abChannel: abChannel
    abApiKey: abApiKey
    freshSalesAPIKey: freshSalesAPIKey
    sftpPasswordKey: sftpPassKey
    sftpUserKey:sftpUserKey
    logAnalyticsWorkspaceId: commonModule.outputs.logAnalyticsWorkspaceId
    logicAppsServerFarmId: commonModule.outputs.logicAppServerFarmId
  }
  dependsOn: [
  ]
}

module gitLinksModule 'modules/gitlinks/main.bicep' = {
  name: 'gitlinks'
  params: {
    userDalId: userModule.outputs.dalId
    b2cHelpersId: userModule.outputs.b2cHelpersId
    articleDalId: articleModule.outputs.dalId
    deviceDalId: deviceModule.outputs.dalId
    userLaId: userModule.outputs.logicAppId
    deviceLaId: deviceModule.outputs.logicAppId
    sharedDeviceLaId: deviceModule.outputs.sharedLogicAppId
  }
  dependsOn: [
    userModule
    articleModule
    deviceModule
  ]
}


output gitLinks array = gitLinksModule.outputs.links
