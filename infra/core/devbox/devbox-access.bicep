targetScope = 'subscription'

param principalId string

// see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var devCenterOwnerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

// The identity that's attached to the dev center should be assigned the Owner role for all the deployment subscriptions and the Reader role for all subscriptions that contain the relevant project
// see: https://learn.microsoft.com/en-us/azure/deployment-environments/how-to-configure-managed-identity#assign-a-subscription-role-assignment-to-the-managed-identity
resource devCenterSubscriptionOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, 'DevCenterOwner', devCenterOwnerRole)
  properties: {
    roleDefinitionId: devCenterOwnerRole
    principalType: 'User' // Group or User
    principalId: principalId
  }
}
