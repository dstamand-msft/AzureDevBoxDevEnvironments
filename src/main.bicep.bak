targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Primary location for all resources')
param location string

@description('The resource group name where the resources will be deployed')
param resourceGroupName string

@description('Deploy the virtual network. If it\'s already created, this should be false')
param deployVnet bool

@description('The RBAC for the devbox')
param devboxRbac object

@description('The artifcats catalog to add')
param catalog object

param vNetName string = ''
param keyVaultPatSecretUri string = ''
param keyVaultName string = ''
@secure()
param keyVaultPatSecretValue string = ''
param devBoxName string = ''
param projectName string = 'Contoso-Demo'
param poolNames array = [{name: 'DevPool', enableLocalAdmin: true, schedule: {}, definition: 'DeveloperBox'}, {name: 'QAPool', enableLocalAdmin: false, schedule: {time: '19:00', timeZone: 'America/Toronto'}, definition: 'QABox'}]
// use az devbox admin sku list for the storage and skus. Sku is the name parameter and storage is the capabilities.value where the name is OsDiskTypes
param definitions array = [{name: 'DeveloperBox', sku: '', storage: ''}, {name: 'QABox', sku: '', storage: ''}]

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var keyVaultPatSecretName = 'REPO-PAT'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module vNet 'core/networking/virtualnetwork.bicep' = {
  name: 'virtualNetwork'
  scope: rg
  params:{
    name: !empty(vNetName) ? vNetName : '${abbrs.networkVirtualNetworks}${resourceToken}'
    location: location
    deployVnet: deployVnet
  }
}

module keyVault 'core/security/keyvault.bicep' = if (empty(keyVaultPatSecretUri)) {
  name: 'keyVault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
  }
}

module keyVaultSecret 'core/security/keyvault-secret.bicep' = if (empty(keyVaultPatSecretUri)) {
  name: 'keyVaultPatSecret'
  scope: rg
  params: {
    name: keyVaultPatSecretName
    keyVaultName: keyVault.outputs.name
    secretValue: keyVaultPatSecretValue
  }
}

module devBox 'core/devbox/devbox.bicep' = {
  name: devBoxName
  scope: rg
  params: {
    name: !empty(devBoxName) ? devBoxName : '${abbrs.devbox}${resourceToken}'
    location: location
    projectName: projectName
    vNetName: vNet.outputs.vNetName
    rsToken: resourceToken
  }
}

// Give the DevCenter access to KeyVault
module keyVaultAccess './core/security/keyvault-access.bicep' = if (empty(keyVaultPatSecretUri)) {
  name: 'devcenter-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: devBox.outputs.identityPrincipalId
  }
}

module devBoxDefinitions 'core/devbox/devbox-definitions.bicep' = {
  name: 'devBoxDefinitions'
  scope: rg
  params: {
    location: location
    devBoxName: devBox.outputs.name
    definitions: definitions
  }
}

module devBoxPools 'core/devbox/devbox-pools.bicep' = {
  name: 'devBoxPools'
  dependsOn: [
    devBoxDefinitions
  ]
  scope: rg
  params: {
    location: location
    devBoxProjectName: devBox.outputs.projectName
    devBoxNetworkConnectionName: devBox.outputs.networkConnectionName
    poolNames: poolNames
  }
}

module devBoxAccess 'core/devbox/devbox-access.bicep' = {
  name: 'devBoxAccess'
  scope: rg
  params: {
    principalId: devboxRbac.principalId
    roleType: devboxRbac.roleType
    projectName: devBox.outputs.projectName
  }
}

module devBoxCatalog 'core/devbox/devbox-catalog.bicep' = {
  name: 'devBoxCatalog'
  scope: rg
  params: {
    devBoxName: devBox.outputs.name
    catalogName: catalog.name
    repositoryType: catalog.repositoryType
    uri: catalog.uri
    branch: catalog.branch
    path: contains(catalog, 'path') ? catalog.path : ''
    patKeyVaultUri: empty(keyVaultPatSecretUri) ? keyVaultSecret.outputs.secretUri : keyVaultPatSecretUri
  }
}
