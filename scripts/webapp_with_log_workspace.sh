#!/bin/sh

RG="simple-express"
WebAppName="simple-express-webapp"
WebAppPlanName="simple-express-plan"
WorkSpaceName="simple-express-log"
Location="northeurope"

# CREATE APP SERVICE
az group create -n $RG --location $Location
az appservice plan create -n $WebAppPlanName -g $RG --is-linux
az webapp create -n $WebAppName --plan $WebAppPlanName -g $RG -i hidetran/simple-express:latest
az webapp config appsettings set -g $RG -n $WebAppName --settings ENV_NAME=development
az webapp restart -n $WebAppName -g $RG

# CREATE LOG WORKSPACE
az monitor log-analytics workspace create --resource-group $rG --workspace-name $WorkSpaceName --sku PerGB2018

# CONFIG WEBAPP DIAGNOSTIC SETTINGS
WebAppResourceId=$(az webapp show --name $WebAppName --resource-group $RG --query id -o tsv | tr -d '\r')
WorkSpaceResourceId=$(az monitor log-analytics workspace show -n $WorkSpaceName -g $RG --query id -o tsv | tr -d '\r')
az monitor diagnostic-settings create --name $WebAppName -g $RG --resource $WebAppResourceId --workspace $WorkSpaceResourceId \
    --metrics '[
        {
          "category": "AllMetrics",
          "enabled": true,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          },
          "timeGrain": null
        }
      ]' \
    --logs '[
        {
          "category": "AppServiceHTTPLogs",
          "categoryGroup": null,
          "enabled": true,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        },
        {
          "category": "AppServiceConsoleLogs",
          "categoryGroup": null,
          "enabled": true,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        },
        {
          "category": "AppServiceAppLogs",
          "categoryGroup": null,
          "enabled": true,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        },
        {
          "category": "AppServiceAuditLogs",
          "categoryGroup": null,
          "enabled": false,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        },
        {
          "category": "AppServiceIPSecAuditLogs",
          "categoryGroup": null,
          "enabled": false,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        },
        {
          "category": "AppServicePlatformLogs",
          "categoryGroup": null,
          "enabled": false,
          "retentionPolicy": {
            "days": 0,
            "enabled": false
          }
        }
      ]'