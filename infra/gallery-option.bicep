// deploys everything related to the custom image
targetScope = 'resourceGroup'

@description('The location of the resources')
param location string = resourceGroup().location

// @description('The name of the Dev Center')
// param devCenterName string

@description('The name of the image template in the image gallery')
param imageGalleryName string = ''

@description('The properties of the image definition in the image gallery.')
param imageDefinitionProperties object

// @description('GitHub organization name that hosts the Azure Deployment Environment code')
// param gitHubOrgName string

@description('The Image builder user identity name')
param imageBuilderIdentityName string = ''

@description('The name of the image template in the image gallery')
param imageTemplateName string = ''

@description('The name of the image definition in the image gallery.')
param imageDefinitionName string = ''

@description('The customization steps for the image')
param customizationSteps array

// resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
//   name: devCenterName
// }

// use https://learn.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-list
// to find the publisher, offer, sku, version
var imageSource = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-21h2-avd'
  version: 'latest'
  baseOs: 'win11multi'
}

// add Image gallery
module imageGallery 'core/devbox/devbox-image-gallery.bicep' = {
  name: 'DevboxGallery'
  params: {
    // imageGalleryName: !empty(imageGaleryName) ? imageGaleryName : '${replace(devCenter.name, '[^a-zA-Z0-9]', '')}Gallery'
    imageGalleryName: imageGalleryName
    imageDefinitionName : imageDefinitionName
    location: location
    imageDefinitionProperties:imageDefinitionProperties
  }
}

module CustomImageDef 'core/virtual-machine-images/virtualmachineimages.bicep' = {
  name: 'CustomImageDef'
  params: {
    imageTemplateName: imageTemplateName
    location: location
    userImageBuilderName: imageBuilderIdentityName
    imageSource: imageSource
    sigImageDefinitionId: imageGallery.outputs.galleryImageId
    sigImageVersion: imageDefinitionProperties.version
    // see the type of object (for the definition), here
    // https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-bicep#imagetemplatecustomizer
    // Note 1: Shell is not available in Windows images
    // Note 2: Any Azure Blob Storage needs to have the image builder identity as Storage Blob Reader RBAC
    customizationSteps: customizationSteps
  }
}

output GalleryName string = imageGallery.outputs.galleryImageName
output GalleryImageTemplateName string = imageTemplateName
