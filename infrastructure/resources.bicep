param containerVersion string
param location string
param integrationResourceGroupName string
param containerAppEnvironmentName string
param containerRegistryName string
param applicationInsightsName string
param serviceBusName string

var systemName = 'tinylnk-proxy'
var defaultResourceName = '${systemName}-ne'
var containerRegistryPasswordSecretRef = 'container-registry-password'

var tables = [
  'shortlinks'
  'hits'
  'hitsbytenminutes'
  'hitstotal'
]
var hitsQueueNames = [
  'hitsprocessorqueue'
  'hitscumulatorqueue'
]

//var apexHostName = 'tinylnk.nl'
var apiHostName = 'proxy.tinylnk.nl'

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: containerAppEnvironmentName
  scope: resourceGroup(integrationResourceGroupName)
  // resource apexCert 'managedCertificates' existing = {
  //   name: '${replace(apexHostName, '.', '-')}-cert'
  // }
  resource apiCert 'managedCertificates' existing = {
    name: '${replace(apiHostName, '.', '-')}-cert'
  }
}
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: containerRegistryName
  scope: resourceGroup(integrationResourceGroupName)
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
  scope: resourceGroup(integrationResourceGroupName)
}

resource apiContainerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: '${defaultResourceName}-ca'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerAppEnvironment.id
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      dapr: {
        enabled: true
        appId: defaultResourceName
        appPort: 80
        appProtocol: 'http'
      }
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        corsPolicy: {
          allowedOrigins: [
            'https://localhost:4200'
            'https://app.tinylnk.nl'
          ]
          allowCredentials: true
          allowedMethods: [
            'GET'
            'POST'
            'PUT'
            'DELETE'
            'OPTIONS'
          ]
        }
        customDomains: [
          // {
          //   name: 'tinylnk.nl'
          //   bindingType: 'SniEnabled'
          //   certificateId: containerAppEnvironment::apexCert.id
          // }
          {
            name: apiHostName
            bindingType: 'SniEnabled'
            certificateId: containerAppEnvironment::apiCert.id
          }
        ]
      }
      secrets: [
        {
          name: containerRegistryPasswordSecretRef
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      maxInactiveRevisions: 1
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.properties.adminUserEnabled ? containerRegistry.name : null
          passwordSecretRef: containerRegistryPasswordSecretRef
        }
      ]

    }
    template: {
      containers: [
        {
          name: defaultResourceName
          image: '${containerRegistry.properties.loginServer}/${systemName}:${containerVersion}'
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 6
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '30'
              }
            }
          }
        ]
      }
    }
  }
}

// module apexCertificateModule 'managedCertificate.bicep' = {
//   name: 'apexCertificateModule'
//   scope: resourceGroup(integrationResourceGroupName)
//   dependsOn: [
//     apiContainerApp
//   ]
//   params: {
//     hostname: apexHostName
//     location: location
//     managedEnvironmentName: containerAppEnvironment.name
//   }
// }
// module apiCertificateModule 'managedCertificate.bicep' = {
//   name: 'apiCertificateModule'
//   scope: resourceGroup(integrationResourceGroupName)
//   dependsOn: [
//     apiContainerApp
//   ]
//   params: {
//     hostname: apiHostName
//     location: location
//     managedEnvironmentName: containerAppEnvironment.name
//   }
// }
