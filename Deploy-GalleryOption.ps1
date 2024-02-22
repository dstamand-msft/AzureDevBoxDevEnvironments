#Requires -Modules Az.ImageBuilder
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$Location,
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$UserIdentityName,
    [Parameter(HelpMessage = "The location of the Bicep template file")]
    [string]$TemplateFile,
    [Parameter(HelpMessage = "The location of the parameters template file")]
    [string]$TemplateParameterFile
)

$InformationPreference = 'Continue'

if ($null -eq $SubscriptionId) {
    # Get existing context
    $currentAzContext = Get-AzContext

    if ($null -eq $currentAzContext) {
        Write-Error "No Azure context found. Please login to Azure using Connect-AzAccount and try again."
        exit 1
    }

    # Get your current subscription ID.
    $SubscriptionId = $currentAzContext.Subscription.Id
}

# $sigSharingFeature = Get-AzProviderPreviewFeature -Name SIGSharing -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
# if ($null -ne $sigSharingFeature) {
#     # see https://learn.microsoft.com/en-us/azure/virtual-machines/share-gallery-direct?tabs=portaldirect
#     Write-Warning "SIGSharing preview feature already enabled, skipping"
# }
# else {
#     Register-AzProviderPreviewFeature -Name SIGSharing -ProviderNamespace Microsoft.Compute
#     Write-Information "SIGSharing preview feature enabled"
# }

$requiresRegistration = @("Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Compute", "Microsoft.VirtualMachineImages")
foreach ($provider in $requiresRegistration) {
    $registeredProvider = Get-AzResourceProvider -ProviderNamespace $provider -ErrorAction SilentlyContinue
    if ($null -eq $registeredProvider) {
        Write-Warning "Provider $provider not registered, registering..."
        Register-AzResourceProvider -ProviderNamespace $provider
        Write-Information "Provider $provider registered"
    }
}

$parameters = Get-Content $TemplateParameterFile | ConvertFrom-Json
$imageTemplateName = $parameters.parameters.imageTemplateName.value
$imageTemplate = Get-AzImageBuilderTemplate -ResourceGroupName $ResourceGroupName -Name $imageTemplateName -ErrorAction SilentlyContinue
if ($null -eq $imageTemplate) {
    Write-Warning "Image template does not exist, skipping deletion..."
}
else {
    Write-Information "Deleting image template..."
    Remove-AzImageBuilderTemplate -ResourceGroupName $ResourceGroupName -Name $imageTemplateName
}

# Check if the identity already exists
Write-Information "Check if the User Identity already exists...`n"
$identity = Get-AzUserAssignedIdentity -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -Name $UserIdentityName -ErrorAction SilentlyContinue
$identityNamePrincipalId = $null

if ($null -ne $identity) {
    Write-Warning "User Identity already exists, skipping creation"
    $identityNamePrincipalId = $identity.PrincipalId
}
else {
    # Create an identity
    $identity = New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $UserIdentityName -SubscriptionId $SubscriptionID -Location $Location
    $identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $UserIdentityName).PrincipalId
    Write-Information "User Identity created"
}

# For VM Image Builder to distribute images, the service must be allowed to inject the images into resource groups.
# To grant the required permissions, create a user-assigned managed identity, and grant it rights on the resource group where the image is built.
Write-Information "Check if role definition for Azure Builder Image exists already exists..."
$imageRoleDefinitionName = "Azure Image Builder Service Image Creation Role-SubId-$SubscriptionID"
# check if role definition already exists
$roleDef = Get-AzRoleDefinition -Name $imageRoleDefinitionName -ErrorAction SilentlyContinue
if ($null -ne $roleDef) {
    Write-Warning "Azure Image Builder Role definition already exists, skipping creation"
}
else {
    Write-Information "The role definition '$imageRoleDefinitionName' for Azure Image Builder will be created at the subscription level to be used across resource groups. Please make sure you have the rights to do so..."
    Read-Host -Prompt "Press any key to continue..."
    # Create a role definition file
    $aibRoleImageCreationUrl = "https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
    $tmpPath = [System.IO.Path]::GetTempPath()
    $aibRoleImageCreationPath = Join-Path -Path $tmpPath -ChildPath "aibRoleImageCreation$(Get-Date -Format "yyyyMMddHHmm").json"

    # Download the configuration
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace ', you should delete or split out as appropriate', '') | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefinitionName) | Set-Content -Path $aibRoleImageCreationPath
    # the template sets the assignable scope to the resource group. Widen it to the subscription as it may be used in other resource groups
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '/resourceGroups/<rgName>', '') | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $SubscriptionID) | Set-Content -Path $aibRoleImageCreationPath

    # Create a role definition
    New-AzRoleDefinition -InputFile $aibRoleImageCreationPath
    Write-Information "Role definition created"
    
    Write-Host "Waiting for the role definition to be available..."
    Start-Sleep -Seconds 30
}

# Check if role assignment already exists
$roleAssignment = Get-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefinitionName -Scope "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName" -ErrorAction SilentlyContinue
if ($null -ne $roleAssignment) {
    Write-Warning "User Identity Role assignment already exists => $($roleAssignment.RoleAssignmentId), skipping creation"
    Write-Warning "If you are experiencing issues, please check the role assignment and set it up manually using the cmdlet New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefinitionName -Scope `"/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName`""
}
else {
    # Grant the role definition to the VM Image Builder service principal
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefinitionName -Scope "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName" -ErrorAction SilentlyContinue
    Write-Information "Role assignment created"
}

Write-Information "If you have referencing any Azure Blob Storage account, in the image template builder, assure that the storage account has the 'Storage Blob Data Reader' role assigned to the identity '$UserIdentityName'"
Write-Information "Set it up manually using the cmdlet New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName `"Storage Blob Data Reader`" -Scope /subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/<your_storage_accoount_name>/blobServices/default/containers/<your_blob_container_name>"
Read-Host -Prompt "Press any key to continue..."

Write-Information "Provisioning resources..."
$deployment = New-AzResourceGroupDeployment -Name "DevBoxImageGalleryOption" `
                              -ResourceGroupName $ResourceGroupName `
                              -TemplateFile $TemplateFile `
                              -TemplateParameterFile $TemplateParameterFile `
                              -imageBuilderIdentityName $identity.Name `
                              -Verbose `
                              -ErrorAction Stop

Write-Information "Resources provisioned"

$imageTemplateName = $deployment.Outputs.galleryImageTemplateName.Value

Write-Information "Running image template..."
Invoke-AzResourceAction `
   -ResourceName $imageTemplateName `
   -ResourceGroupName $ResourceGroupName `
   -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
   -ApiVersion "2022-02-14" `
   -Action Run `
   -Force

$choices = '&Yes', '&No'
while ($true) {
    $output = Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $ResourceGroupName | Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState
    $output | Format-Table -AutoSize
    if ($output.ProvisioningState -eq "Succeeded") {
        break
    }
    Start-Sleep -s 30
    $response = $Host.UI.PromptForChoice("Monitor the image template Build", "Do you want to continue monitoring the image template build ?", $choices, 0)
    if ($response -eq 1) {
        break
    }
}
