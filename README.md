# Example to show Go and Azure Kubernetes Service in Action

This is a simple app to illustrate the ease of configuration and deployment of
a Go application in the cloud. This is not enterprise ready.

## Prerequisites

- Azure CLI (https://learn.microsoft.com/en-us/cli/azure/)
- Docker (https://docker.com/)
- GNU Make (https://www.gnu.org/software/make/)
- Go 1.20 (https://go.dev/)
- kubectl (https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli#connect-to-the-cluster)

## TL;DR
1. Install any prerequisites
2. Create a free tier account on Azure (https://portal.azure.com/)
3. Create the environment file by running `make envfile`, for ease of getting setup use the following contents:
```
APP_NAME=griffin
AZURE_REGION=eastus
AZURE_RESOURCE_GROUP=${APP_NAME}rg
AZURE_AKS_CLUSTER_NAME=${APP_NAME}aks
AZURE_ACR_NAME=${APP_NAME}acr
```
NOTE: If changing the application name please update the `ops/deployment.yml` image to match. This remains hardcoded as it seems like extra steps that doesn't fit the scope of the example.

4. Run

  `make shipItAll`

5. Test the endpoint for a response

  `make healthTest`

6. When finished, we remove everything

  `make cleanThisBecauseIKnowWhatImDoing`

## Architecture

We're setting up the following in azure to support the project:
- Azure Resource Group
- Azure Container Registry
- Azure Kubernetes Service
- Configures all related networking, etc. out of the box

## Application

We've used Go as the language for the example. It builds using a multi-stage Dockerfile to provide the smallest final image. Without the multi-stage the image was ~400mb, and with it brings it down to ~5mb.

## Command usage

We've chosen Make to allow us to gradually move more items into a 3 Musketeers design pattern. Ideally, all commands here would have no prerequisites besides Make, Docker and potentially Compose if needed for our use cases.

The commands are broken out into individual pieces e.g. `make createResourceGroup`, we can perform this task separately or glue it with something more substantial by creating the resource group and all other infrastructure `make infra`. This allows us to test things in isolation during the development of the IaC solution, and furthermore automate it in a pipeline.

## Example scenarios

I made changes to `ops/main.bicep` and want to deploy my changes:

`make azureBicep`

I made changes to the Go code, and want to format and run unit tests:

`make fmt test`

My application has been modified and I need to deploy:

1. Update the `ops/deployment.yml` to include the new image tag e.g. "image: griffinacr.azurecr.io/griffin:YOUR_TAG"
2. `make buildAndPush deploy VERSION=YOUR_TAG`

Note: Editing the deployment.yml manually is not ideal but made simpler for this example.

I'd like to access the public IP of the Load Balancer:

`make getPublicIp`

I want to create docker tags, and share them without deploying:

`make tagImage pushImage VERSION=exampleTag`

## Commands

| Command | Description |
| ------------- | ------------- |
| help | Describes the Makefile targets |
| envfile | Generate the required `.env` file |
| createResourceGroup | Create the Resource Group defined in `.env` |
| azureBicep | Create or update infrastructure in `ops/main.bicep` |
| infra | Create all infrastructure |
| build | Build docker container for Go application |
| buildAndPush | Build, Tag and Push image to Azure Container Registry |
| shipItAll | Creates all infrastructure, builds applications and deploys it. |
| deploy | Deploy default application |
| getPublicIp | Get the LoadBalancer Address |
| pushImage | Push image to Azure Container Registry |
| tagImage | Tag the built image for use on Azure Container Registry |
| acrLogin | Helper: Logs into ACR. Used in other targets |
| mountKubectl | Attach to the remote session so we can run local kubectl commands |
| cleanThisBecauseIKnowWhatImDoing | Destructive: Removes Entire Resource Group |
| healthTest | Fetch endpoint to verify it's returning |
| healthLoad | Run AB for small load test |
