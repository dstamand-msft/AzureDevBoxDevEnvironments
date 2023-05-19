param devBoxName string
param patKeyVaultUri string
param catalogName string
@allowed([ 'ado', 'gitHub' ])
param repositoryType string
param uri string
param branch string
@description('The folder path where the artifacts are located')
param path string = ''

var properties = repositoryType == 'ado' ? {
  adoGit: {
    uri: uri
    branch: branch
    path: path
    secretIdentifier: patKeyVaultUri
  }
} : {
  gitHub: {
    uri: uri
    branch: branch
    path: path
    secretIdentifier: patKeyVaultUri
  }
}

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
  name: devBoxName
}

resource devCenterCatalog 'Microsoft.DevCenter/devcenters/catalogs@2023-01-01-preview' = {
  parent: devCenter
  name: catalogName
  properties: properties
}
