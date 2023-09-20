param principalId string
@allowed(['Group', 'User'])
param roleType string
param projectName string

// see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var devCenterProjectAdminRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')

resource devBoxProject 'Microsoft.DevCenter/projects@2023-01-01-preview' existing = {
  name: projectName
}

resource keyVaultSecretsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: devBoxProject // Use when specifying a scope that is different than the deployment scope
  name: guid(principalId, 'DevCenterAdmin', devCenterProjectAdminRole)
  properties: {
    roleDefinitionId: devCenterProjectAdminRole
    principalType: roleType // Group or User
    principalId: principalId
  }
}
