param publisherEmail string = 'markus.meyer@plan-b-gmbh.com'
param publisherName string = 'Markus'

@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

param skuCount int = 1

param location string = resourceGroup().location

var logAnalyticsWorkspaceName = 'log-rfq'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'Standalone'
    }
  })
}

resource logAnalyticsWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: logAnalyticsWorkspace
  name: 'diagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

var appInsightsName = 'appi-rfq'
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var apiManagementServiceName = 'demorfqapiservice${uniqueString(resourceGroup().id)}'

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    disableGateway: false
  }
}

resource apiManagementServiceLogger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  name: '${apiManagementService.name}/${appInsights.name}'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: '{{${namedValueAppInsightsKey.properties.displayName}}}'
    }
  }
}

resource namedValueAppInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apiManagementService.name}/AppInsightsKey'
  properties: {
    displayName: 'AppInsightsKey'
    value: appInsights.properties.InstrumentationKey
    secret: true
    tags: [
      'AppInsights'
    ]
  }
}

resource namedValueTinyUrlKey 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apiManagementService.name}/TinyUrlKey'
  properties: {
    displayName: 'TinyUrlKey'
    value: '-na-'
    secret: true
    tags: [
      'TinyUrl'
    ]
  }
}

resource namedValueEvaluationApiKey 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apiManagementService.name}/EvaluationApiKey'
  properties: {
    displayName: 'EvaluationApiKey'
    value: '-na-'
    secret: true
    tags: [
      'Evaluation'
    ]
  }
}

resource petStoreApiExample 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: '${apiManagementService.name}/PetStoreSwaggerImportExample'
  properties: {
    format: 'openapi+json-link'
    value: 'https://petstore3.swagger.io/api/v3/openapi.json'
    path: 'examplepetstore'
  }
}

resource encomDevelopersProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  name: '${apiManagementService.name}/encomDevelopers'
  properties: {
    displayName: 'Encom Developers'
    description: 'Developers from Encom'
    terms: 'Terms for Encom'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource productStarterPetStoreApiExample 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  name: '${apiManagementService.name}/starter/${substring(petStoreApiExample.name, lastIndexOf(petStoreApiExample.name, '/') + 1 , length(petStoreApiExample.name)-lastIndexOf(petStoreApiExample.name, '/')-1) }'
}

resource appInsightsPetStoreApiExample 'Microsoft.ApiManagement/service/apis/diagnostics@2021-08-01' = {
  name: '${petStoreApiExample.name}/applicationinsights'
  properties:  {
    loggerId: apiManagementServiceLogger.id
    alwaysLog: 'allErrors'
    verbosity: 'verbose'
    httpCorrelationProtocol: 'W3C'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    backend: {
      request: {
         body: {
            bytes: 8192
         }
      }
      response: {
        body: {
          bytes: 8192
       }  
      }
    }
    frontend: {
      request: {
        body: {
           bytes: 8192
        }
     }
     response: {
       body: {
         bytes: 8192
      }  
     }    
     }
  }
}

resource apiManagementServiceGateway 'Microsoft.ApiManagement/service/gateways@2021-08-01' = {
  name: 'EvaluationGateway'
  parent: apiManagementService
  properties: {
    description: 'For evaluation'
    locationData: {
      city: 'Augsburg'
      countryOrRegion: 'Bavaria'
      district: 'Schwabia'
      name: 'Höme'
    }
  }
}
