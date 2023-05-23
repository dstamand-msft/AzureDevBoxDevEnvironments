# Dev Box and Dev Environments

![image](https://github.com/dstamand-msft/AzureDevBoxDevEnvironments/blob/main/media/DevBox-Creation.png)

# Deployment examples
Use the follow commands (using Az PowerShell)

Providing a PAT, which will create the keyvault to store it
```powershell
$ghPATToken = ConvertTo-SecureString -String "PAT_TOKEN" -AsPlainText -Force
New-AzDeployment -Name DevBox -Location EastUS2 -TemplateFile .\src\main.bicep -TemplateParameterFile .\src\main.parameters.jsonc -keyVaultPatSecretValue $ghPATToken -Verbose
```