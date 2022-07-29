#!/bin/sh

RG="simple-express"
WebApp1Name="simple-express-1"
WebApp2Name="simple-express-2"
PlanName="simple-express-plan"
Location="northeurope"

EventHubNamespace="simple-express-eventhub"
EventHubName="simple-express"

StorageAccountName="simpleexpressa"
StorageContainerName="eventhub"

# CREATE RESOURCE GROUP
az group create --name $RG --location $Location

# CREATE EVENT HUB NAMESPACE
az eventhubs namespace create --name $EventHubNamespace -g $RG --location $Location --sku Standard

# CREATE EVENT HUB UNDER AN EVENT HUB NAMESPACE
az eventhubs eventhub create --name $EventHubName \
                             --namespace-name $EventHubNamespace \
                             --resource-group $RG \
                             --partition-count 3

# CREATE STORAGE ACCOUNT
az storage account create --name $StorageAccountName --resource-group $RG
az storage container create --name $StorageContainerName --account-name $StorageAccountName

# CREATE APP SERVICE PLAN
az appservice plan create -n $PlanName -g $RG --is-linux

# CREATE APP1, ADD SETTINGS AND RESTART
az webapp create -n $WebApp1Name --plan $PlanName -g $RG -i hidetran/simple-express:latest
az webapp config appsettings set -g $RG -n $WebApp1Name --settings ENV_NAME=simple-express-1
az webapp restart -n $WebApp1Name -g $RG

# CREATE APP2, ADD SETTINGS AND RESTART
az webapp create -n $WebApp2Name --plan $PlanName -g $RG -i hidetran/simple-express:latest
az webapp config appsettings set -g $RG -n $WebApp2Name --settings ENV_NAME=simple-express-2
az webapp restart -n $WebApp2Name -g $RG