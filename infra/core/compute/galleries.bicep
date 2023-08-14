@minLength(1)
@sys.description('Required. Name of the Azure Compute Gallery.')
param name string

@sys.description('Optional. Location for all resources.')
param location string = resourceGroup().location

@sys.description('Optional. Tags for all resources.')
param tags object = {}

@sys.description('Optional. Description of the Azure Shared Image Gallery.')
param description string = ''

resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: name
  location: location
  tags: tags
  properties: {
    description: description
    identifier: {}
  }
}

output name string = gallery.name
output id string = gallery.id
