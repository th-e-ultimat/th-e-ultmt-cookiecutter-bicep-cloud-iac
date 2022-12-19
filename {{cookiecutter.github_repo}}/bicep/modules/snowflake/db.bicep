param component string
param environmentType string
param location string
param prefix string

param adminLogin string

@secure()
param adminPassword string

var tags = {
  component: component
  environment: environmentType
}

var dbServerSku = environmentType == 'qa' ? {
  name: 'Standard_B1ms'
  tier: 'Burstable'
} : {
  name: 'Standard_B2s'
  tier: 'Burstable'
}

param serverName string = '${prefix}-psql-${component}-${environmentType}'
resource dbServer 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {}
    highAvailability: {
      mode: 'Disabled'
    }
    version: '13'
  }
  
  sku: dbServerSku
}

resource dbServerFirewallRulesAllowAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2021-06-01' = {
  parent: dbServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

var databaseName = 'snowflake'
resource db 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2021-06-01' = {
  parent: dbServer
  name: databaseName
}

output dbServerName string = dbServer.name
output dbName string = db.name
