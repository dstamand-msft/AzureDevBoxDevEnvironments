param imageTemplateName string
param api_version string
param svclocation string

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@[parameters(\'api-version\')]' = {
  name: imageTemplateName
  location: svclocation
  tags: {
    imagebuilderTemplate: 'win11multi'
    userIdentity: 'enabled'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '<imgBuilderId>': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 60
    vmProfile: {
      vmSize: 'Standard_B8as_v2'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-11'
      sku: 'win11-21h2-avd'
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'customscript'
        scriptUri: 'https://raw.githubusercontent.com/Keayoub/AzureDevBoxDevEnvironments/main/scripts/imageBuilderScripts/installDevToolsImage.ps1'
        runElevated: true
        runAsSystem: true
      }
      {
        type: 'WindowsRestart'
      }
      {
        type: 'PowerShell'
        name: 'customscript'
        scriptUri: 'https://raw.githubusercontent.com/Keayoub/AzureDevBoxDevEnvironments/main/scripts/imageBuilderScripts/Run-app.ps1'
        runElevated: true
        runAsSystem: true
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: '/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<sharedImageGalName>/images/<imageDefName>'
        runOutputName: '<runOutputName>'
        artifactTags: {
          source: 'azureVmImageBuilder'
          baseosimg: 'win11multi'
        }
        replicationRegions: [
          '<region1>'
          '<region2>'
        ]
      }
    ]
  }
  dependsOn: []
}