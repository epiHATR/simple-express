#!/bin/sh

RG="simple-express-prod"
WebAppName="simple-express-prod"
WebAppPlanName="simple-express-prod"
AppInsightName="simple-express-prod"
Location="northeurope"

az group create -n $RG --location $Location
az appservice plan create -n $WebAppPlanName -g $RG --is-linux
az webapp create -n $WebAppName --plan $WebAppPlanName -g $RG -i hidetran/simple-express:latest
az webapp config appsettings set -g $RG -n $WebAppName --settings ENV_NAME=production
az webapp restart -n $WebAppName -g $RG

az monitor app-insights component create --app $AppInsightName \
                                         --location $Location \
                                         --resource-group $RG \
                                         --kind java

az monitor app-insights component connect-webapp --app $AppInsightName \
                                                 --resource-group $RG \
                                                 --web-app $WebAppName \
                                                 --enable-profiler --enable-snapshot-debugger

connectionString=$(az monitor app-insights component show --app $AppInsightName -g $RG --query connectionString -o tsv)
az webapp config appsettings set -g $RG -n $WebAppName --settings ApplicationInsightsAgent_EXTENSION_VERSION=~2
az webapp config appsettings set -g $RG -n $WebAppName --settings APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString

az webapp restart -n $WebAppName -g $RG