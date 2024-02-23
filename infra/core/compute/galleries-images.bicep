@minLength(1)
@sys.description('Required. Name of the Azure Compute Gallery Image.')
param name string

@minLength(1)
@sys.description('Required. Name of the Azure Compute Gallery.')
param galleryName string

@sys.description('Optional. Location for all resources.')
param location string = resourceGroup().location

@sys.description('Required. The type of the image.')
@sys.allowed([ 'Windows' ])
param osType string

@sys.description('Optional. Tags of the resource.')
param tags object = {}

@sys.description('Optional. Description of the Azure Shared Image Gallery.')
param description string = ''

@sys.description('Required. Detailed image information to set for the custom image produced by the Azure Image Builder build. Requires publisher, offer, sku')
param imageDefinitionProperties object

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galleryName
}

resource galleryImage 'Microsoft.Compute/galleries/images@2022-03-03' = {
  name: name
  location: location
  tags: tags
  parent: gallery
  properties: {
    architecture: 'x64'
    description: description
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    // enable hybernation on the image
    // see https://learn.microsoft.com/en-us/azure/dev-box/how-to-configure-dev-box-hibernation#enable-hibernation-on-your-dev-box-image
    features: [
      {
        name: 'IsHibernateSupported'
        value: 'true'
      }      
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
    ]
    osType: osType
    identifier: {
      publisher: imageDefinitionProperties.publisher
      offer: imageDefinitionProperties.offer
      sku: imageDefinitionProperties.sku
    }
  }
}

output id string = galleryImage.id
