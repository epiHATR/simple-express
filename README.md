#### login into Azure CR
az login -t <tenant id>
az account set -s  <subscription id>
az acr login --name episervercrdev

#### run build
docker build -t hidetran/simple-express:prod -f Dockerfile . --platform=linux/amd64

#### tagging
docker tag episervercrdev.azurecr.io/hidetran/simple-express:prod hidetran/simple-express:prod

#### publish the docker image
docker push episervercrdev.azurecr.io/hidetran/simple-express:prod