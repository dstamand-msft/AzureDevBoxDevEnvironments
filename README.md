# Dev Box and Dev Environments

![image](https://github.com/dstamand-msft/AzureDevBoxDevEnvironments/blob/main/media/DevBox-Creation.png)

### Prerequisites

#### To Run Locally

- [Azure Developer CLI](https://aka.ms/azure-dev/install)
- [Git](https://git-scm.com/downloads)
- [Powershell 7+ (pwsh)](https://github.com/powershell/powershell)

  - **Important**: Ensure you can run `pwsh.exe` from a PowerShell command. If this fails, you likely need to upgrade PowerShell.

> NOTE: Your Azure Account must have `Microsoft.Authorization/roleAssignments/write` permissions, such as [User Access Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) or [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner).

#### To Run in GitHub Codespaces or VS Code Remote Containers

You can run this repo virtually by using GitHub Codespaces or VS Code Remote Containers. Click on one of the buttons below to open this repo in one of those options.

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/dstamand-msft/AzureDevBoxDevEnvironments)
[![Open in Remote - Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/dstamand-msft/AzureDevBoxDevEnvironments)

### Installation using Azd deployment

#### Project Initialization

1. Create a new folder **your_folder_name**
2. git clone <https://github.com/dstamand-msft/AzureDevBoxDevEnvironments.git> **your_folder_name**
3. switch to your **your_folder_name** in the terminal
4. Run `azd auth login`

#### Starting from scratch

Execute the following command, if you don't have any pre-existing Azure services and want to start from a fresh deployment.

Start by initializing azd
```powershell
azd init
```

1. Set variables values for your first run :

```powershell
azd env set AZURE_LOCATION "LOCATION"
azd env set AZURE_RESOURCE_GROUP "YOUR RESOURCE GROUP NAME"
azd env set AZURE_SUBSCRIPTION_ID "************************************"
azd env set GITHUB_ORG_NAME "YOUR_GITHUB_ORG_NAME"
# ObjectId of the User or Group that will be DevCenter Project Admin in the project
azd env set AZURE_DEVBOX_PROJECT_ADMIN_PRINCIPALID ""
# User or Group
azd env set AZURE_DEVBOX_PROJECT_ADMIN_ROLETYPE "" 
azd env set keyVaultPatSecretValue "***********************************"
# only if you want to deploy a custom image
azd env set AZURE_IMAGE_BUILDER_IDENTITY "IMAGE BUILDER IDENTITY NAME"
azd env set AZURE_IMAGE_TEMPLATE_NAME "devbox-ibt-1"
# Allowed characters are English alphanumeric characters, with underscores and periods allowed in the middle, up to 80 characters total.
# All other special characters, including dashes, are disallowed.
azd env set AZURE_GALLERY_NAME "galdevboxdemo"
azd env set AZURE_GALLERY_IMAGE_DEF "myDevBoxCustomImage"
```

Azure Developer CLI uses an environment name to set the `AZURE_ENV_NAME` environment variable that's used by Azure Developer CLI templates. `AZURE_ENV_NAME` is also used to prefix the Azure resource group name. Because each environment has its own set of configurations, Azure Developer CLI stores all configuration files in environment directories.
This environment variable is set when you run `azd init` or `azd env new`.

2. Change the property deployVnet to **true** if you want to create a new VNET

```JSON
 "deployVnet": {
    "value": true
 },
```

3. If you want to deploy custom Image Template with your DevCenter Change the property deployCustomImage to **true** otherwise keep it as **false**

```JSON
 "deployCustomImage": {
    "value": true
 },
```


3. Run `azd up` - This will provision Azure resources and deploy this sample to those resources.

#### Using existing resources

1. Run `azd env set AZURE_SUBSCRIPTION_ID {Name of existing subscription}`
1. Run `azd env set AZURE_RESOURCE_GROUP {Name of existing resource group that provisioned to}`
1. Run `azd env set AZURE_DEVBOX_NAME {Name of existing DevBox deployment}`
1. Run `azd env set AZURE_DEVBOX_VNET_NAME {Name of existing VNET deployment}`. You need also to change in your main.parameters.json value of deployVnet to false
1. Run `azd env set keyVaultPatSecretValue {Value of your github PAT_TOKEN Providing a PAT, which will create the keyvault to store it}`
1. Run `azd up`

> NOTE: See `./infra/main.parameters.json` for list of environment variables to pass to `azd env set` to configure those existing resources.

#### Deploying again

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
   | deployVnet        | Boolean   | Yes      | True for initial deployment of the virtual network. If it's already created, this should be false                                                                                                       |
   | devboxRbac        | GUID/Text | Yes      | Provide the principalId (objectId) and roleType (User or Group) for the principal that will be granted admin on the project                                                                                                                                                    |

3. Open the YAML pipeline located under \.pipelines\devbox-deply.yml and modify the parameters.
4. As indicated, ensure the Service connection has **'Microsoft.Authorization/roleAssignments/write'** permissions.
