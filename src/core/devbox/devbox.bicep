param name string
param location string = resourceGroup().location
param tags object = {}

param projectName string
param vNetName string
param subnetName string = 'default'

resource devBox 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {}
}

resource attachednetworks 'Microsoft.DevCenter/devcenters/attachednetworks@2023-01-01-preview'= {
  parent: devBox
  name: '${devBox.name}-NetConnection'
  properties: {
    networkConnectionId: devBoxNetworkConnection.id
  }
}

resource devBoxProjects 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: projectName
  location: location
  properties: {
    devCenterId: devBox.id
  }
}

resource devBoxNetworkConnection 'Microsoft.DevCenter/networkConnections@2023-01-01-preview' = {
  name: '${devBox.name}-NetConnection'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: subnet.id
    networkingResourceGroupName: 'NI_${devBox.name}-NetConnection_${toLower(location)}'
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vNetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: vNet
}

output name string = devBox.name
output networkConnectionName string = devBoxNetworkConnection.name
output projectName string = devBoxProjects.name
