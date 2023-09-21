param name string
param location string = resourceGroup().location
param tags object = {}

param projectName string
param vNetName string
param subnetName string = 'default'
param environmentTypes array = ['QualityInsurance', 'Development']
param rsToken string

var devCenterOwnerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {}
  identity: {
    type: 'SystemAssigned'
  }
}

resource devCenterEnvironment 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in environmentTypes : {
  parent: devCenter
  name: envType
  properties: {}
}]

resource attachednetworks 'Microsoft.DevCenter/devcenters/attachednetworks@2023-01-01-preview'= {
  parent: devCenter
  name: '${devCenter.name}-NetConnection-${rsToken}'
  properties: {
    networkConnectionId: devCenterNetworkConnection.id
  }
}

resource devCenterProject 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: projectName
  location: location
  properties: {
    devCenterId: devCenter.id
  }
}

resource projectXEnvironmentType 'Microsoft.DevCenter/projects/environmentTypes@2023-01-01-preview' = [for envType in environmentTypes : {
  parent: devCenterProject
  name: envType
  properties: {
    deploymentTargetId: subscription().id
    status: 'Enabled'
    creatorRoleAssignment:{
      roles: {
        // reader role
        'acdd72a7-3385-48ef-bd42-f606fba81ae7': {}
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}]

resource devCenterNetworkConnection 'Microsoft.DevCenter/networkConnections@2023-01-01-preview' = {
  name: '${devCenter.name}-NetConnection-${rsToken}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: subnet.id
    networkingResourceGroupName: 'NI_${devCenter.name}-NetConnection_${toLower(location)}'
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vNetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: vNet
}

output name string = devCenter.name
output networkConnectionName string = devCenterNetworkConnection.name
output projectName string = devCenterProject.name
output identityPrincipalId string = devCenter.identity.principalId
