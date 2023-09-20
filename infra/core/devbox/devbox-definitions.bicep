param location string = resourceGroup().location
param devBoxName string
param definitions array
param galleryName string = 'Default'

@allowed(['win11', 'vs2022win11m365'])
param image string = 'vs2022win11m365'


var defaultImageMap = {
  win11: 'microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-os'
  vs2022win11m365: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
}

var defaultMachineSku = skuMap.vm8core32memory
var skuMap = {
  vm8core32memory: 'general_i_8c32gb256ssd_v2'
}

@allowed(['ssd_256gb', 'ssd_512gb', 'ssd_1024gb'])
param defaultMachineStorage string = 'ssd_256gb'


resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
  name: devBoxName
}

resource devBoxGallery 'Microsoft.DevCenter/devcenters/galleries@2023-01-01-preview' existing = {
  name: galleryName
  parent: devCenter
}

resource galleryimage 'Microsoft.DevCenter/devcenters/galleries/images@2022-11-11-preview' existing = {
  name: defaultImageMap['${image}']
  parent: devBoxGallery
}
output imageGalleryId string = galleryimage.id

resource devboxDefinitions 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-01-01-preview' = [for item in definitions: {
  parent: devCenter
  name: item.name
  location: location
  properties: {
    sku: {
      name: !empty(item.sku) ? item.sku: defaultMachineSku
    }
    imageReference: {
      id: galleryimage.id
    }
    osStorageType: !empty(item.storage) ? item.storage: defaultMachineStorage
    hibernateSupport: 'Disabled'
  }
}]

