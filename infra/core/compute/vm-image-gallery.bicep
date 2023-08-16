param location string = resourceGroup().location
param imageDefinitionName string
param imageDefinitionProperties object
param imageGalleryName string = ''
param imageName string = '' 
param userdIdentity string = ''



// use https://learn.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-list
// to find the publisher, offer, sku, version
var imageReferenceWindows11Barebone = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-21h2-pro'
  version: 'latest'
}

// var imageReferenceUbuntu = {
//   type: 'PlatformImage'
//   publisher: 'Canonical'
//   offer: '0001-com-ubuntu-server-jammy'
//   sku: '22_04-lts'
//   version: 'latest'
// }

module imageGallery 'galleries.bicep'= {
  name: 'imageGallery'
  params: {
    name: imageGalleryName
    location: location
  }
}

module imageGalleryImage 'galleries-images.bicep' = {
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
  name: userdIdentity
  location: location
}

//TODO: bugFix : Bicep not creation custom image version
// module vmImage '../virtual-machine-images/virtualmachineimages.bicep' = {
//   name: 'vmImage'  
//   params: {
//     name: imageName
//     location: location
//     userMsiName: userAssignedIdentity.name
//     // see the type of object (for the definition), here
//     // https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-bicep#imagetemplatecustomizer
//     customizationSteps: [
//       {
//         type: 'WindowsUpdate'
//         searchCriteria: 'IsInstalled=0'
//         filters: [
//           'exclude:$_.Title -like \'*Preview*\''
//           'include:$true'
//         ]
//         updateLimit: 40
//       }
//     ]
//     imageSource: imageReferenceWindows11Barebone
//     sigImageDefinitionId: imageGalleryImage.outputs.id
//   }
// }
