#!/bin/sh

WebApp_RG="simple-express"
WebApp_Name="simple-express-1"
WebApp_PlanName="simple-express-plan"
ImageName="hidetran/simple-express:latest"

CacheRG="simple-redis"
CacheName="simple-redis"
Sku="basic"
Size="C0"

Location="northeurope"

# create az resource group for WebApp
az group create --name $WebApp_RG --location $Location

# create az app service plan & webapp
az appservice plan create -n $WebApp_PlanName -g $WebApp_RG --is-linux
az webapp create -n $WebApp_Name --plan $WebApp_PlanName -g $WebApp_RG -i $ImageName

# create az resource group for Azure Caches for Redis
az group create --name $CacheRG --location $Location
az redis create --name $CacheName --resource-group $CacheRG --location $Location --sku $Sku --vm-size $Size

# get Azure Caches for Redis details
az redis show --name $CacheName --resource-group $CacheRG 

# Retrieve the hostname and ports for an Azure Redis Cache instance
caches=($(az redis show --name $CacheName --resource-group $CacheRG --query [hostName,sslPort] --output tsv))

# Retrieve the keys for an Azure Redis Cache instance
primaryKey=$(az redis list-keys --name $CacheName --resource-group $CacheRG --query [primaryKey] --output tsv | tr -d '\r')

# config app settings
az webapp config appsettings set -g $WebApp_RG -n $WebApp_Name --settings ENV_NAME=production
az webapp config appsettings set -g $WebApp_RG -n $WebApp_Name --settings CACHES_URL=${caches[0]}
az webapp config appsettings set -g $WebApp_RG -n $WebApp_Name --settings CACHES_PORT=${caches[1]}
az webapp config appsettings set -g $WebApp_RG -n $WebApp_Name --settings CACHES_KEY=$primaryKey

az webapp restart -n $WebApp_Name -g $WebApp_RG