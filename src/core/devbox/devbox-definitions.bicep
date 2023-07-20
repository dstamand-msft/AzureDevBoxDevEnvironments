param location string = resourceGroup().location

param devBoxName string
param definitions array 
param machinesVMImageName string = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'

var defaultMachineSku = 'general_i_8c32gb256ssd_v2'
var defaultMachineStorage = 'ssd_256gb'

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
  name: devBoxName
}

resource devBoxGallery 'Microsoft.DevCenter/devcenters/galleries@2023-01-01-preview' existing = {
  name: 'Default'
  parent: devCenter
}

resource devboxDefinitions 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-01-01-preview' = [for item in definitions: {
  parent: devCenter
  name: item.name
  location: location
  properties: {
    imageReference: {
      id: '${devBoxGallery.properties.galleryResourceId}/images/${machinesVMImageName}'
    }
    sku: {
      name: !empty(item.sku) ? item.sku: defaultMachineSku
    }
    osStorageType: !empty(item.storage) ? item.storage: defaultMachineStorage
  }
}]
