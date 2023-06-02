param location string = resourceGroup().location

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('The name of the image definition in the image gallery.')
param imageDefinitionName string

@description('The properties of the image definition in the image gallery.')
param imageDefinitionProperties object

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// use https://learn.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-list
// to find the publisher, offer, sku, version
var imageReferenceWindows11Barebone = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-22h2-pro'
  version: 'latest'
}

// var imageReferenceUbuntu = {
//   type: 'PlatformImage'
//   publisher: 'Canonical'
//   offer: '0001-com-ubuntu-server-jammy'
//   sku: '22_04-lts'
//   version: 'latest'
// }

module imageGallery 'core/compute/galleries.bicep' = {
  name: 'imageGallery'
  params: {
    name: '${abbrs.gallery}${resourceToken}'
    location: location
  }
}

module imageGalleryImage 'core/compute/galleries-images.bicep' = {
  name: 'imageGalleryImage'
  params: {
    name: imageDefinitionName
    location: location
    galleryName: imageGallery.outputs.name
    osType: 'Windows'
    imageDefinitionProperties: imageDefinitionProperties
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  location: location
}

module vmImage 'core/virtual-machine-images/virtualmachineimages.bicep' = {
  name: 'vmImage'
  params: {
    name: '${abbrs.imageTemplate}${resourceToken}'
    location: location
    userMsiName: userAssignedIdentity.name
    // see the type of object (for the definition), here
    // https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-bicep#imagetemplatecustomizer
    customizationSteps: [
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
      }
    ]
    imageSource: imageReferenceWindows11Barebone
    sigImageDefinitionId: imageGalleryImage.outputs.id
  }
}
