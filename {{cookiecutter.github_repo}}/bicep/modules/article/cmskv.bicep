param cmsKeyVaultName string
param dalPrincipalId string

resource cmsKeyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: cmsKeyVaultName
  scope: resourceGroup()
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  parent: cmsKeyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: dalPrincipalId
        tenantId: subscription().tenantId
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'list'
            'get'
          ]
          storage: []
        }
      }
    ]
  }
}
