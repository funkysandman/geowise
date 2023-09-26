targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@maxLength(5)
param randomString string

@minLength(1)
@description('Primary location for all resources')
param location string

param aadClientId string = ''
param buildNumber string = 'local'
param isInAutomation bool = false

param appServicePlanName string = ''
param resourceGroupName string = ''
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param backendServiceName string = ''
param storageAccountName string = ''
param containerName string = 'content'
param cosmosdbName string = ''

param AZURE_OPENAI_API_ENDPOINT string = ''
param AZURE_OPENAI_API_VERSION string = ''
param AZURE_OPENAI_SERVICE_KEY string = ''
param AZURE_OPENAI_CHATGPT_DEPLOYMENT string = ''
param AZURE_OPENAI_GPT4_DEPLOYMENT string = ''
param AZURE_MAPS_KEY string = ''


@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('abbreviations.json')
var tags = { ProjectName: 'GeoWise', BuildNumber: buildNumber }
var prefix = 'geowise'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${prefix}-${environmentName}'
  location: location
  tags: tags
}

module logging 'core/logging/logging.bicep' = {
  name: 'logging'
  scope: rg
  params: {
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${prefix}-${abbrs.logAnalytics}${randomString}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${prefix}-${abbrs.appInsights}${randomString}'
    location: location
    tags: tags
    skuName: 'PerGB2018'
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${prefix}-${abbrs.webServerFarms}${randomString}'
    location: location
    tags: tags
    sku: {
      name: 'p1v3'
      capacity: 2
    }
    kind: 'linux'
  }
}

// The application frontend
module backend 'core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(backendServiceName) ? backendServiceName : '${prefix}-${abbrs.webSitesAppService}${randomString}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    applicationInsightsName: logging.outputs.applicationInsightsName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsName
    appSettings: {
      AZURE_BLOB_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_BLOB_STORAGE_CONTAINER: containerName
      AZURE_BLOB_STORAGE_KEY: storage.outputs.key
      APPINSIGHTS_INSTRUMENTATIONKEY: logging.outputs.applicationInsightsInstrumentationKey
      COSMOSDB_URL: cosmosdb.outputs.CosmosDBEndpointURL
      COSMOSDB_KEY: cosmosdb.outputs.CosmosDBKey
      COSMOSDB_DATABASE_NAME: cosmosdb.outputs.CosmosDBDatabaseName
      COSMOSDB_CONTAINER_NAME: cosmosdb.outputs.CosmosDBContainerName
      AZURE_OPENAI_API_ENDPOINT: AZURE_OPENAI_API_ENDPOINT
      AZURE_OPENAI_API_VERSION: AZURE_OPENAI_API_VERSION
      AZURE_OPENAI_SERVICE_KEY:AZURE_OPENAI_SERVICE_KEY
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: AZURE_OPENAI_CHATGPT_DEPLOYMENT
      AZURE_OPENAI_GPT4_DEPLOYMENT: AZURE_OPENAI_GPT4_DEPLOYMENT
      AZURE_MAPS_KEY: AZURE_MAPS_KEY

    }
    aadClientId: aadClientId
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${prefix}${abbrs.storageStorageAccounts}${randomString}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    sku: {
      name: 'Standard_LRS'
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containers: [
      {
        name: containerName
        publicAccess: 'None'
      }    
    ]
    queueNames: [  
    ]
  }
}

module cosmosdb 'core/db/cosmosdb.bicep' = {
  name: 'cosmosdb'
  scope: rg
  params: {
    name: !empty(cosmosdbName) ? cosmosdbName : '${prefix}-${abbrs.cosmosDBAccounts}${randomString}'
    location: location
    tags: tags
    databaseName: 'geodb'
    containerName: 'locations'
  }
}


module storageRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: isInAutomation ? 'ServicePrincipal': 'User'
  }
}

module storageContribRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-contribrole-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: isInAutomation ? 'ServicePrincipal': 'User'
  }
}

module storageRoleBackend 'core/security/role.bicep' = {
  scope: rg
  name: 'storage-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}


output AZURE_LOCATION string = location
output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_CONTAINER string = containerName
output AZURE_STORAGE_KEY string = storage.outputs.key
output BACKEND_URI string = backend.outputs.uri
output BACKEND_NAME string = backend.outputs.name
output RESOURCE_GROUP_NAME string = rg.name
output AZURE_COSMOSDB_URL string = cosmosdb.outputs.CosmosDBEndpointURL
output AZURE_COSMOSDB_KEY string = cosmosdb.outputs.CosmosDBKey
output AZURE_COSMOSDB_DATABASE_NAME string = cosmosdb.outputs.CosmosDBDatabaseName
output AZURE_COSMOSDB_CONTAINER_NAME string = cosmosdb.outputs.CosmosDBContainerName
output BLOB_CONNECTION_STRING string = storage.outputs.connectionString
output APP_SERVICE_PLAN string = appServicePlan.outputs.name
output AzureWebJobsStorage string = storage.outputs.connectionString
