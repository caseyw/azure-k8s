VERSION ?= latest
GO_RUN = docker run -it --rm -p 8090:8090 -v ./src:/app -w /app golang:1.20.4-alpine

help: envfile ## Describes the Makefile targets.
	@printf "\033[33mUsage:\033[0m\n  make [target] [ARG=\"val\"...]\n\n\033[33mTargets:\033[0m\n"
	@grep -E '^[-a-zA-Z0-9_\.\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/\Makefile://g' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

envfile: ## Generate the required .env
	@[ -f ".env" ] || cp .env.template .env

shipItAll: infra buildAndPush deploy ## Ship infrastructure and application

infra: createResourceGroup azureBicep  ## Create all infrastructure

createResourceGroup: ## Create Resource Group
	az group create -l ${AZURE_REGION} -n ${AZURE_RESOURCE_GROUP}

azureBicep: ## Create or update infrastructure
	az deployment group create \
		--resource-group ${AZURE_RESOURCE_GROUP} \
		--template-file ops/main.bicep \
		--parameters appName=${APP_NAME} acrName=${AZURE_ACR_NAME} aksName=${AZURE_AKS_CLUSTER_NAME}

buildAndPush: build tagImage pushImage ## Build, Tag and Push image to Azure Container Registry

build: ## Build docker container
	docker build -f ops/Dockerfile -t ${APP_NAME}:${VERSION} . --platform linux/amd64

tagImage: ## Tag the built image for use on Azure Container Registry
	docker tag ${APP_NAME}:${VERSION} ${AZURE_ACR_NAME}.azurecr.io/${APP_NAME}:${VERSION}

pushImage: acrLogin ## Push image to Azure Container Registry
	docker push ${AZURE_ACR_NAME}.azurecr.io/${APP_NAME}:${VERSION}

acrLogin: ## Helper: Logs into ACR. Used in other targets
	az acr login --name ${AZURE_ACR_NAME}

deploy: mountKubectl ## Deploy default application
	kubectl apply -f ops/deployment.yml

mountKubectl: ## Attach to the remote session
	az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${AZURE_AKS_CLUSTER_NAME}

# Application development and testing

dev: ## Run project locally during development
	${GO_RUN} go run main.go

test: ## Run unit test project locally during development
	${GO_RUN} go test

fmt: ## Format the Go code to keep it up to date with standards
	${GO_RUN} gofmt -w .

# Helper targets

watch:
	kubectl get service frontend --watch

healthLoad: ## Run AB to verify system spun up
	docker run --rm jordi/ab -c 20 -n 200 http://$(shell kubectl get services frontend --output jsonpath='{.status.loadBalancer.ingress[0].ip}')/

healthTest: ## Fetch endpoint to verify it's returning
	@echo
	@curl http://$(shell kubectl get services frontend --output jsonpath='{.status.loadBalancer.ingress[0].ip}')/
	@echo
	@echo

cleanThisBecauseIKnowWhatImDoing: ## Destructive: Removes Entire Resource Group
	az group delete --name ${AZURE_RESOURCE_GROUP} --yes

getPublicIp: ## Get the LoadBalancer Address
	@echo "http://$(shell kubectl get services frontend --output jsonpath='{.status.loadBalancer.ingress[0].ip}')"

.PHONY: help envfile shipItAll infra createResourceGroup azureBicep buildAndPush build tagImage pushImage acrLogin deploy mountKubectl dev test fmt watch healthLoad healthTest cleanThisBecauseIKnowWhatImDoing getPublicIp

include $(PWD)/.env