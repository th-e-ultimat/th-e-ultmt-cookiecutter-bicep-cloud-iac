param component string
param environmentType string
param location string
param prefix string

var tags = {
  component: component
  environment: environmentType
}

param databaseName string = 'main'
param userContainerName string = 'user'
param deviceContainerName string = 'device'
param partitionKey string = '/partitionKey'


param notificationContainerName string = 'notification'

// param deviceSn string = '/deviceSerialNumber'


resource dbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: '${prefix}-cosmos-${component}-${environmentType}'
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAnalyticalStorage: true
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

resource mainDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: dbAccount
  name: databaseName
  tags: tags
  properties: {
    resource: {
      id: databaseName
    }
  }
}



resource notificationContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: notificationContainerName
  tags: tags
  parent: mainDb
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
    resource: {
      analyticalStorageTtl: -1
      
      id: notificationContainerName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/data/*'
          }
        ]
      }
      partitionKey: {
        paths: [
          partitionKey
        ]
      }
    }
  }
}


// TODO: configure throughput per environment
resource userContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: mainDb
  name: userContainerName
  tags: tags
  properties: {
    resource: {
      id: userContainerName
      partitionKey: {
        paths: [
          partitionKey
        ]
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/data/*'
          }
        ]
      }

      analyticalStorageTtl: -1
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

// TODO: configure throughput per environment
resource deviceContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: mainDb
  name: deviceContainerName
  tags: tags
  properties: {
    resource: {
      id: deviceContainerName
      partitionKey: {
        paths: [
          partitionKey
        ]
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/data/*'
          }
        ]
      }
      analyticalStorageTtl: -1
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

var primaryConnectionString = listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', dbAccount.name), dbAccount.apiVersion).connectionStrings[0].connectionString

output accountName string = dbAccount.name
output mainDbName string = mainDb.name
output primaryConnectionString string = primaryConnectionString
output notificationContainerName string = notificationContainer.name
output userContainerName string = userContainer.name
output deviceContainerName string = deviceContainer.name
