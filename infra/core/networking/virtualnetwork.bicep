param name string
param location string = resourceGroup().location
param tags object = {}
param deployVnet bool

resource vNet 'Microsoft.Network/virtualNetworks@2022-07-01' = if(deployVnet)  {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: 'default'
  parent: vNet
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
}

output vNetName string = vNet.name
