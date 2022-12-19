param component string
param environmentType string
param location string
param prefix string

param linuxServerFarmId string

param dbServerName string
param dbAdminLogin string

@secure()
param dbAdAdminPassword string

var tags = {
  component: component
  environment: environmentType
}


var dbUrl = 'postgresql://${dbAdminLogin}:${dbAdAdminPassword}@${dbServerName}.postgres.database.azure.com/postgres'

var webAppName = '${prefix}-wa-${component}-${environmentType}'
resource webApp 'Microsoft.Web/sites@2018-11-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'SNOWFLAKE_API_PORT'
          value: '8000'
        }
        {
          name: 'SNOWFLAKE_DATABASE_URL'
          value: dbUrl
        }
      ]
      linuxFxVersion: 'PYTHON|3.7'
    }
    serverFarmId: linuxServerFarmId
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
