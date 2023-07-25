# Dev Box and Dev Environments

![image](https://github.com/dstamand-msft/AzureDevBoxDevEnvironments/blob/main/media/DevBox-Creation.png)

# Deployment examples
Use the follow commands (using Az PowerShell)

Providing a PAT, which will create the keyvault to store it
```powershell
$ghPATToken = ConvertTo-SecureString -String "PAT_TOKEN" -AsPlainText -Force
New-AzDeployment -Name DevBox -Location EastUS2 -TemplateFile .\src\main.bicep -TemplateParameterFile .\src\main.parameters.jsonc -keyVaultPatSecretValue $ghPATToken -Verbose
```

# Deploy using pipeline

1. Open the Bicep parameters file, located under \src\main.parameters.jsonc
2. Configure the following parameters

    | Variable | Type | Required | Description | 
    | :--- | :--- | :--- | :--- |
    | environmentName | Text |  Yes | Name of the environment which is used to generate a short unique hash used in all resources | 
    | Location | Text | Yes | Primary location for all resources, [determine availbility in desired region](https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/?products=dev-box&regions=all&rar=true) | 
    | resourceGroupName | Text | Yes | The resource group name where the resources will be deployed | 
    | deployVnet | Boolean | Yes | True for initial deployment of the virtual network. If it\'s already created, this should be false | 
    | devboxRbac | GUID/Text | Yes | Provide the principalId and roleType (User or Group) |

3. Open the YAML pipeline located under \.pipelines\devbox-deply.yml and modify the parameters.
4. As indicated, ensure the Service connection has **'Microsoft.Authorization/roleAssignments/write'** permissions.

# Deploy using Azure CLI
## deploy using Az Cli

az deployment sub create --location "eastus" --template-file main.bicep --parameters  main.parameters.jsonc --parameters keyVaultPatSecretValue="GitHub_PAT"