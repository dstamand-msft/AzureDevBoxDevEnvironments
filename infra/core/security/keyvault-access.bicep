param principalId string
param keyVaultName string

// see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var keyVaultSecretsUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault // Use when specifying a scope that is different than the deployment scope
  name: guid(principalId, 'Secrets', keyVaultSecretsUserRole)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

