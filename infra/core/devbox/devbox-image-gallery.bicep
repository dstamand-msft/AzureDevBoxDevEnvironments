param location string = resourceGroup().location
param imageGalleryName string = ''
param imageDefinitionName string
param imageDefinitionProperties object

module imageGallery '../compute/galleries.bicep' = {
  name: 'imageGallery'
  params: {
    name: imageGalleryName
    location: location
  }
}

module imageGalleryDefinition '../compute/galleries-images.bicep' = {
  name: 'imageGalleryDefinition'
  params: {
    name: imageDefinitionName
    location: location
    galleryName: imageGallery.outputs.name
    osType: 'Windows'
    imageDefinitionProperties: imageDefinitionProperties
  }
}

output galleryImageId string = imageGalleryDefinition.outputs.id
output galleryImageName string = imageGalleryName
