param location string = resourceGroup().location

param devBoxProjectName string
param devBoxNetworkConnectionName string
param poolNames array

resource devCenterProject 'Microsoft.DevCenter/projects@2023-01-01-preview' existing = {
  name: devBoxProjectName
}

resource pools 'Microsoft.DevCenter/projects/pools@2023-01-01-preview' = [for item in poolNames: {
  parent: devCenterProject
  name: item.name
  location: location
  properties: {
    devBoxDefinitionName: item.definition
    licenseType: 'Windows_Client'
    localAdministrator: item.enableLocalAdmin ? 'Enabled' : 'Disabled'
    networkConnectionName: devBoxNetworkConnectionName
  }
}]

resource poolsSchedules 'Microsoft.DevCenter/projects/pools/schedules@2023-01-01-preview' = [for (item, i) in poolNames: if (!empty(item.schedule)) {
  dependsOn: [
    pools[i]
  ]
  name: '${devBoxProjectName}/${pools[i].name}/default'
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: item.schedule.time
    timeZone: item.schedule.timeZone
  }
}]
