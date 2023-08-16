param location string = resourceGroup().location
param imageDefinitionName string
param imageDefinitionProperties object
param imageGalleryName string = ''
param imageName string = ''
param userdIdentity string = ''

// use https://learn.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-list
// to find the publisher, offer, sku, version
var imageSource = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: 'win11-21h2-avd'
  version: 'latest'
}

var imageSourceLinux = {
  type: 'PlatformImage'
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts'
  version: 'latest'
}

module devboxImageGallery '../compute/galleries.bicep' = {
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
    galleryName: devboxImageGallery.outputs.name
    osType: 'Windows'
    imageDefinitionProperties: imageDefinitionProperties
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userdIdentity
  location: location
}


module vmImage '../virtual-machine-images/virtualmachineimages.bicep' = {
  name: 'vmImage'
  params: {
    name: imageName
    location: location
    userMsiName: userAssignedIdentity.name    
    // see the type of object (for the definition), here
    // https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-bicep#imagetemplatecustomizer    
    imageSource: imageSource
    sigImageDefinitionId: imageGalleryDefinition.outputs.id
    customizationSteps: [
      {
        type: 'PowerShell'
        name: 'Install Choco and Vscode and DevTools'
        inline: [
          'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(\'https://community.chocolatey.org/install.ps1\'))'
          'choco install -y vscode'
          'choco install -y git'
          'choco install -y googlechrome'
          'choco install 7zip -y'
          'choco install adobereader -y'
          'choco install azcopy10 -y'
          'choco install azure-cli -y'
          'choco install azure-iot-installer -y'
          'choco install docker-desktop -y'
          'choco install Firefox -y'
          'choco install flux -y'
          'choco install gh -y'
          'choco install git -y'
          'choco install github-desktop -y'
          'choco install paint.net -y'
          'choco install pulumi -y'
          'choco install pwsh -y'
          'choco install terraform -y'        
        ]
      }
      {
        type: 'PowerShell'
        name: 'Install application from git repo'
        inline: [
          'git clone "https://github.com/dockersamples/example-voting-app.git" voting-app'
          'cd voting-app'
          'docker compose up'          
        ]
      }     
    ]
  }
}

// module vmLinuxImage '../virtual-machine-images/virtualmachineimages.bicep' = {
//   name: 'vmLinuxImage'
//   params: {
//     name: '${imageName}-linux'
//     location: location
//     userMsiName: userAssignedIdentity.name    
//     // see the type of object (for the definition), here
//     // https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/imagetemplates?pivots=deployment-language-bicep#imagetemplatecustomizer    
//     imageSource: imageSourceLinux
//     sigImageDefinitionId: imageGalleryDefinition.outputs.id
//     customizationSteps: [
//       {
        
//       }
//     ]
//   }
// }
