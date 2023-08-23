# Dev Box and Dev Environments

![image](https://github.com/dstamand-msft/AzureDevBoxDevEnvironments/blob/main/media/DevBox-Creation.png)

### Prerequisites

#### To Run Locally

- [Azure Developer CLI](https://aka.ms/azure-dev/install)
- [Git](https://git-scm.com/downloads)
- [Powershell 7+ (pwsh)](https://github.com/powershell/powershell) - For Windows users only.
  - **Important**: Ensure you can run `pwsh.exe` from a PowerShell command. If this fails, you likely need to upgrade PowerShell.

> NOTE: Your Azure Account must have `Microsoft.Authorization/roleAssignments/write` permissions, such as [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner).

#### To Run in GitHub Codespaces or VS Code Remote Containers

You can run this repo virtually by using GitHub Codespaces or VS Code Remote Containers. Click on one of the buttons below to open this repo in one of those options.

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/Keayoub/AzureDevBoxDevEnvironments)
[![Open in Remote - Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Keayoub/AzureDevBoxDevEnvironments)

### Installation using Azd deployment

#### Project Initialization

1. Create a new folder **your_folder_name**
2. git clone <https://github.com/Keayoub/AzureDevBoxDevEnvironments.git> **your_folder_name**
3. switch to your **your_folder_name** in the terminal
4. Run `azd auth login`

#### Starting from scratch

Execute the following command, if you don't have any pre-existing Azure services and want to start from a fresh deployment.

1. Set variables values for your first run :

```powershell
azd env set AZURE_ENV_NAME="YOUR ENVIRONNEMENT NAME"
azd env set AZURE_IMAGE_BUILDER_IDENTITY="IMAGE BUILDER IDENTITY NAME"
azd env set AZURE_LOCATION="LOCATION"
azd env set AZURE_RESOURCE_GROUP="YOUR RESOURCE GROUP NAME"
azd env set AZURE_SUBSCRIPTION_ID="************************************"
azd env set keyVaultPatSecretValue="***********************************"
```

2. Change the property deployVnet to true if you VNET doesn't exists

```JSON
 "deployVnet": {
    "value": true
 },
```

3. Run `azd up` - This will provision Azure resources and deploy this sample to those resources.

#### Using existing resources

1. Run `azd env set AZURE_SUBSCRIPTION_ID {Name of existing OpenAI service}`
1. Run `azd env set AZURE_RESOURCE_GROUP {Name of existing resource group that provisioned to}`
1. Run `azd env set AZURE_DEVBOX_NAME {Name of existing DevBox deployment}`
1. Run `azd env set AZURE_DEVBOX_VNET_NAME {Name of existing VNET deployment}`. You need also to change in your main.parameters.json value of deployVnet to false
1. Run `azd env set keyVaultPatSecretValue {Value of your github PAT_TOKEN Providing a PAT, which will create the keyvault to store it}`
1. Run `azd up`

> NOTE: You can also use existing Search and Storage Accounts. See `./infra/main.parameters.json` for list of environment variables to pass to `azd env set` to configure those existing resources.

#### Deploying again

If you've only changed the backend/frontend code in the `app` folder, then you don't need to re-provision the Azure resources. You can just run:

`azd deploy`

If you've changed the infrastructure files (`infra` folder or `azure.yaml`), then you'll need to re-provision the Azure resources. You can do that by running:

`azd up`

# AZ Deployment examples

if you want to use Az or powershell deployment your can use the follow commands (using Az PowerShell)

Providing a PAT, which will create the keyvault to store it

```powershell
$ghPATToken = ConvertTo-SecureString -String "PAT_TOKEN" -AsPlainText -Force
New-AzDeployment -Name DevBox -Location EastUS2 -TemplateFile .\src\main.bicep -TemplateParameterFile .\src\main.parameters.jsonc -keyVaultPatSecretValue $ghPATToken -Verbose
```

# Deploy using pipeline

1. Open the Bicep parameters file, located under \src\main.parameters.jsonc
2. Configure the following parameters

   | Variable          | Type      | Required | Description                                                                                                                                                                                              |
   | :---------------- | :-------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | environmentName   | Text      | Yes      | Name of the environment which is used to generate a short unique hash used in all resources                                                                                                              |
   | Location          | Text      | Yes      | Primary location for all resources, [determine availbility in desired region](https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/?products=dev-box&regions=all&rar=true) |
   | resourceGroupName | Text      | Yes      | The resource group name where the resources will be deployed                                                                                                                                             |
   | deployVnet        | Boolean   | Yes      | True for initial deployment of the virtual network. If it\'s already created, this should be false                                                                                                       |
   | devboxRbac        | GUID/Text | Yes      | Provide the principalId and roleType (User or Group)                                                                                                                                                     |

3. Open the YAML pipeline located under \.pipelines\devbox-deply.yml and modify the parameters.
4. As indicated, ensure the Service connection has **'Microsoft.Authorization/roleAssignments/write'** permissions.
