param name string
param location string = resourceGroup().location
param tags object = {}

resource devBox 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags  
}
