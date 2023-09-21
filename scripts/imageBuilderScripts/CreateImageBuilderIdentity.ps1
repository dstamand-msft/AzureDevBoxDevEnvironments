<#
Image builder requires a user assigned identity to be created in the subscription that has a specific set of permissions.
See https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-permissions-powershell for more details.
#>
Write-Host "`r`nInstalling required Az modules...`r`n" -ForegroundColor Cyan

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
'Az.Resources', 'Az.ImageBuilder', 'Az.Compute' | ForEach-Object {
    if (Get-Module -ListAvailable -Name $_) {
        Write-Host "$_ Already installed" -ForegroundColor Yellow
    }
    else {
        try {
            Install-Module -Name $_ -AllowClobber -Confirm:$False -Force
        }
        catch [Exception] {
            $_.message
            exit 1
        }
    }
}

Write-Host "`r`nLoading azd .env file from current environment`r`n" -ForegroundColor Cyan

$output = azd env get-values
foreach ($line in $output) {
    if (!$line.Contains('=')) {
        continue
    }

    $name, $value = $line.Split("=")
    $value = $value -replace '^\"|\"$'
    [Environment]::SetEnvironmentVariable($name, $value)
}

Write-Host "`r`nEnvironment variables set.`r`n" -ForegroundColor Cyan

# Get your current subscription ID
$subscriptionID = "$env:AZURE_SUBSCRIPTION_ID"
# Destination image resource group
$resourceGroupName = "$env:AZURE_RESOURCE_GROUP"
# Location
$location = "$env:AZURE_LOCATION"

# Set up role def names, which need to be unique
$identityName = "$env:AZURE_IMAGE_BUILDER_IDENTITY"
$imageRoleDefName = "Azure Image Builder Image Def " + $identityName

# check if subscription is set before continuing
if ($null -eq $subscriptionID) {
    Write-Host "Subscription not set, exiting..."
    exit 0
}

#check if resource group exists and create it if not
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $resourceGroup) {
    Write-Host "Resource group not found, creating..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

#Check if the identity already exists
Write-Host "`r`nCheck if the identity already exists...`r`n"

$identity = Get-AzUserAssignedIdentity -SubscriptionId $subscriptionID -ResourceGroupName $resourceGroupName -Name $identityName -ErrorAction SilentlyContinue
$identityNamePrincipalId = $null

if ($null -ne $identity) {
    Write-Information "Identity already exists, skipping creation"
    $identityNamePrincipalId = $identity.PrincipalId
}
else {
    # Create an identity
    New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName -SubscriptionId $subscriptionID -Location $location
    $identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName).PrincipalId
}

# For VM Image Builder to distribute images, the service must be allowed to inject the images into resource groups.
# To grant the required permissions, create a user-assigned managed identity, and grant it rights on the resource group where the image is built. 
Write-Host "Check if role definition already exists..."
# check if role definition already exists
$roleDef = Get-AzRoleDefinition -Name $imageRoleDefName -ErrorAction SilentlyContinue
if ($null -ne $roleDef) {
    Write-Host "Role definition already exists, skipping creation"
}
else {
    # Create a role definition file
    $aibRoleImageCreationUrl = "https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
    $tmpPath = [System.IO.Path]::GetTempPath()
    $aibRoleImageCreationPath = Join-Path -Path $tmpPath -ChildPath "aibRoleImageCreation$(Get-Date -Format "yyyyMMddHHmm").json"

    # Download the configuration
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $resourceGroupName) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

    # Create a role definition
    New-AzRoleDefinition -InputFile $aibRoleImageCreationPath
}

# Check if role assignment already exists
$roleAssignment = Get-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$resourceGroupName" -ErrorAction SilentlyContinue
if ($null -ne $roleAssignment) {
    Write-Host "Role assignment already exists, skipping creation"
}
else {
    # Grant the role definition to the VM Image Builder service principal
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$resourceGroupName" -ErrorAction SilentlyContinue
}