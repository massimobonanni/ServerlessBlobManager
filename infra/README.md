# Serverless Blob Manager - IaC

Bicep templates used by the [Azure Developer CLI](https://aka.ms/azd) to provision the environment that hosts the Serverless Blob Manager project.

## Layout

```
infra/
|-- main.bicep                          # subscription-scope orchestration entry point
|-- main.parameters.json                # maps AZD environment values to Bicep parameters
|-- modules/
    |-- storage.bicep                   # the storage account to manage (soft delete enabled)
    |-- functionApp.bicep               # function app, plan, runtime storage, Application Insights
    |-- storageRoleAssignment.bicep     # blob data access on the managed storage account
    |-- eventGrid.bicep                 # system topic on the managed storage account
    |-- eventGridViewer.bicep           # optional Event Grid Viewer web app and subscription
```

The subscription that routes `Microsoft.Storage.BlobDeleted` events to the function is created by the azd `postdeploy` hook in `scripts/azd`, because Event Grid requires the target function to already exist.

## Deploy with azd

```
azd auth login
azd env new <environment-name>
azd up
```

`azd up` provisions the infrastructure and deploys the `func` service declared in `azure.yaml`.

### Optional settings

| Variable | Default | Description |
| --- | --- | --- |
| `DEPLOY_EVENT_GRID_VIEWER` | `true` | Deploys the Event Grid Viewer web app. |

Set them with `azd env set <name> <value>`. Provisioning outputs (function app name, managed storage account, Event Grid Viewer URL) are written to the AZD environment and can be read with `azd env get-values`.

> `azd provision` alone does not create the BlobDeleted subscription. Use `azd up` (or `azd deploy`) so the postdeploy hook runs after the function code is published.

To remove everything: `azd down --purge`.

## Deploy with the Azure CLI

```
az deployment sub create --location <region> --template-file main.bicep --parameters environmentName=<name> location=<region>
```

where

- `environmentName` is the name used to build the resource names and tags
- `location` is the region where you want to deploy
