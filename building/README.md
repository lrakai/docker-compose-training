# docker-software-delivery
Demonstration of developing, testing, and delivering production software with Docker.

## Overview
The MEAN stack application code in `src/` is used to demonstrate how to:
- Containerize a multi-tier application
- Create development and test environments with Docker Compose
- Create production environments using Docker Compose override files
- Release a new feature from development, through test, and into production

## Getting Started
An Azure Resource Manager template is provided in `infrastructure/` to create an environment with three virtual machines in a virtual network with Docker installed on each. Certificates are shared and setup for TLS secured communication between the three Docker hosts. The created environment resembles the following:
<img src="https://user-images.githubusercontent.com/3911650/27996794-58870aa8-64a7-11e7-8227-e1f137603dba.png" alt="Azure environment">
You can also directly visualize the template resources:

<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Flrakai%2Fdocker-software-delivery%2Fmaster%2Finfrastructure%2Farm-template.json">
    <img src="https://camo.githubusercontent.com/536ab4f9bc823c2e0ce72fb610aafda57d8c6c12/687474703a2f2f61726d76697a2e696f2f76697375616c697a65627574746f6e2e706e67" data-canonical-src="http://armviz.io/visualizebutton.png" style="max-width:100%;">
</a> 

A Resource Manager policy to allow only the creation of the required resources is also included in `infrastructure/`.

### One-Click Deploy
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flrakai%2Fdocker-software-delivery%2Fmaster%2Finfrastructure%2Farm-template.json">
    <img src="https://camo.githubusercontent.com/9285dd3998997a0835869065bb15e5d500475034/687474703a2f2f617a7572656465706c6f792e6e65742f6465706c6f79627574746f6e2e706e67" data-canonical-src="http://azuredeploy.net/deploybutton.png" style="max-width:100%;">
</a>

### Using PowerShell
The following command sequence can prepare the environment in the West US 2 Azure region:
```ps1
Login-AzureRmAccount
New-AzureRmResourceGroup -Name docker -Location westus2
New-AzureRmResourceGroupDeployment -ResourceGroupName docker -TemplateFile .\infrastructure\arm-template.json -Name dsd
```
When finished, the following can tear down the environment:
```ps1
Remove-AzureRmResourceGroup -Name docker
```

## Useful Commands
### Registry VM
To create a registry on the registry vm enter:
```sh
docker run -d --name registry \
           --restart=always \
           -v /etc/docker/:/certs \
           -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/cert.pem \
           -e REGISTRY_HTTP_TLS_KEY=/certs/key.pem \
           -p 5000:5000 \
           registry:2
```
The registry is accessible from with the virtual network at registry.ca-labs.com:5000

### Development VM
After cloning the source code, unit test the code
```sh
npm install
npm test
```

Build the image:
```sh
docker build -t registry.ca-labs.com:5000/accumulator:1 registry.ca-labs.com:5000/accumulator:1.0 .
```

Push the image to the registry:
```sh
docker push registry.ca-labs.com:5000/accumulator:1
docker push registry.ca-labs.com:5000/accumulator:1.0
```

Integration test the applicaiton using Docker Compose:
```sh
docker-compose up -d
bash integration.sh
docker-compose down
```

Simplify communication with the production VM by moving certificates to the user's default .docker directory:
```sh
mkdir ~/.docker
sudo cp /etc/docker/ca.pem \
        /etc/docker/cert.pem \
        /etc/docker/key.pem \
        ~/.docker
sudo chown student ~/.docker/*
```

Start the application on the production VM using Docker Compose the production override file:
```sh
DOCKER_HOST=production.ca-labs.com:2376 DOCKER_TLS_VERIFY=true docker-compose \
    -f docker-compose.yml \
    -f docker-compose.prod.yml \
    up \
    -d
```

Update the application with v1.1 of the source code which includes a new feature:
```sh
cp -R src/commits/v1_1/. src
```

Build the v1.1 container image:
```sh
docker build -t registry.ca-labs.com:5000/accumulator:1 registry.ca-labs.com:5000/accumulator:1.1 .
```

Push the new image to the registry:
```sh
docker push registry.ca-labs.com:5000/accumulator:1
docker push registry.ca-labs.com:5000/accumulator:1.1
```

Pull the new version of the image onto the production VM:
```sh
DOCKER_HOST=production.ca-labs.com:2376 DOCKER_TLS_VERIFY=true docker-compose pull
```

Update only the app service to deploy the new feature and keep the database up:
```sh
DOCKER_HOST=production.ca-labs.com:2376 DOCKER_TLS_VERIFY=true docker-compose \
    -f docker-compose.yml \
    -f docker-compose.prod.yml \
    up \
    -d \
    --no-deps \
    app
```
