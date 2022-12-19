@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])

param component string
param environmentType string
param location string
param prefix string

@secure()
@description('Password to use for SFTP access')
param sftpPassword string

@description('Username to use for SFTP access')
param sftpUser string = 'sftp'

@description('Storage account type')
param storageAccountType string = 'Standard_LRS'

@description('DNS label for container group')
param containerGroupDNSLabel string = uniqueString(resourceGroup().id, deployment().name)

@description('Name of file share to be created')
param fileShareName string = 'sftpfileshare'

var storageAccountName = '${prefix}sftpsa${component}${environmentType}'

var sftpContainerName = '${prefix}-sftp-${component}-leadforwarding-${environmentType}'
var sftpContainerGroupName = '${prefix}-sftp-group-${component}-leadforwarding-${environmentType}'

var sftpContainerImage = 'atmoz/sftp:debian'
var sftpEnvVariable = '${sftpUser}:${sftpPassword}:1001'


resource stgacct 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku:{
    name: storageAccountType
  }
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: toLower('${stgacct.name}/default/${fileShareName}')
}

resource containergroup 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: sftpContainerGroupName
  location: location
  properties: {
    containers: [
      {
        name: sftpContainerName
        properties: {
          image: sftpContainerImage
          environmentVariables: [
            {
              name: 'SFTP_USERS'
              secureValue: sftpEnvVariable
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          ports:[
            {
              port: 22
              protocol: 'TCP'
            }
          ]
          volumeMounts: [
            {
              mountPath: '/home/${sftpUser}/upload'
              name: 'sftpvolume'
              readOnly: false
            }
          ]
        }
      }
    ]

    osType:'Linux'
    ipAddress: {
      type: 'Public'
      ports:[
        {
          port: 22
          protocol:'TCP'
        }
      ]
      dnsNameLabel: containerGroupDNSLabel
    }
    restartPolicy: 'OnFailure'
    volumes: [
      {
        name: 'sftpvolume'
        azureFile:{
          readOnly: false
          shareName: fileShareName
          storageAccountName: stgacct.name
          storageAccountKey: listKeys(stgacct.id, '2019-06-01').keys[0].value
        }
      }
    ]
  }
}

output sftpContainerDNSLabel string = '${containergroup.properties.ipAddress.dnsNameLabel}.${containergroup.location}.azurecontainer.io'
