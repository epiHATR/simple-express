#Build locally
docker build -t hidetran/simple-express:local -f Dockerfile .

#Publish docker by tag
docker push hidetran/simple-express:local