@description('Provide Application Name')
param appName string

@description('Provide a globally unique name of your Azure Container Registry')
param acrName string

@description('Provide name for Azure Kubernetes Service')
param aksName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'


resource aks 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: '${appName}pre'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 2
        vmSize: 'standard_d2s_v3'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    enableRBAC: true
    privateLinkResources: [
      {
        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().id}/providers/Microsoft.ContainerRegistry/registries/${acr.name}'
        groupId: 'acrPull'
      }
    ]
  }
}

output controlPlaneFQDN string = aks.properties.fqdn




resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true
  }
}

@description('Output the login server property for later use')
output loginServer string = acr.properties.loginServer




var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aks.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
