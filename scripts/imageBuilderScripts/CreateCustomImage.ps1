Write-Host ""
Write-Host "Installing required Az modules..."
Write-Host ""
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
'Az.Resources', 'Az.ImageBuilder', 'Az.ManagedServiceIdentity', 'Az.Compute' | ForEach-Object { Install-Module -Name $_ -AllowClobber -Force -Confirm:$false }

Write-Host ""
Write-Host "Loading azd .env file from current environment"
Write-Host ""

$output = azd env get-values
foreach ($line in $output) {
    if (!$line.Contains('=')) {
        continue
    }

    $name, $value = $line.Split("=")
    $value = $value -replace '^\"|\"$'
    [Environment]::SetEnvironmentVariable($name, $value)
}
Write-Host ""
Write-Host "Environment variables set."
Write-Host ""
 
# Get your current subscription ID  
$subscriptionID = "$env:AZURE_SUBSCRIPTION_ID"
# Destination image resource group  
$resourceGroupName = "$env:AZURE_RESOURCE_GROUP"
# Location  
$location = "$env:AZURE_LOCATION"

# Set up role def names, which need to be unique 
$identityName = "$env:AZURE_IMAGE_BUILDER_IDENTITY"
$imageRoleDefName = "Azure Image Builder Image Def " + $identityName 
  
#Check if the identity already exists
Write-Host ""
Write-Host "Check if the identity already exists..."
Write-Host ""

$identity = Get-AzUserAssignedIdentity -SubscriptionId $subscriptionID -ResourceGroupName $resourceGroupName -Name $identityName -ErrorAction SilentlyContinue
$identityNameResourceId = $null
$identityNamePrincipalId = $null

if ($null -ne $identity) {
    Write-Information "Identity already exists, skipping creation"
    $identityNameResourceId = $identity.Id 
    $identityNamePrincipalId = $identity.PrincipalId
}
else {
    # Create an identity 
    New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName -SubscriptionId $subscriptionID -Location $location
    $identityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName).Id 
    $identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName).PrincipalId    
}

Write-Host "Check if role definition already exists..."
# check if role definition already exists
$roleDef = Get-AzRoleDefinition -Name $imageRoleDefName -ErrorAction SilentlyContinue
if ($null -ne $roleDef) {
    Write-Host "Role definition already exists, skipping creation"    
}
else {    
    # Create a role definition file 
    $aibRoleImageCreationUrl = "https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json" 
    $aibRoleImageCreationPath = "aibRoleImageCreation.json" 

    # Download the configuration 
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing 
        ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath 
        ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $resourceGroupName) | Set-Content -Path $aibRoleImageCreationPath 
        ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath 

    # Create a role definition 
    New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json    
}

# Grant the role definition to the VM Image Builder service principal 
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -SubscriptionId $subscriptionID  -Scope "/subscriptions/$subscriptionID/resourceGroups/$resourceGroupName"

Write-Host ""
Write-Host "Creating image template..."
Write-Host ""

# Image distribution metadata reference name  
$runOutputName = "aibCustWinManImg01"  
# Image template name  
$imageTemplateName = "CustomDevImgTemplate"

# Create a gallery image definition
# Gallery name 
$galleryName = "devboxGallery" 

# Image definition name 
$imageDefName = "customImageDef" 

# Additional replication region 
$replRegion2 = "eastus" 

# Create the gallery 
#check is gallery already exists 
$gallery = Get-AzGallery -ResourceGroupName $resourceGroupName -Name $galleryName -ErrorAction SilentlyContinue
if ($null -ne $gallery) {
    Write-Host "Gallery already exists, skipping creation"
}
else {
    Write-Host "Creating gallery..."
    New-AzGallery -GalleryName $galleryName -ResourceGroupName $resourceGroupName -Location $location 
}

$SecurityType = @{Name = 'SecurityType'; Value = 'TrustedLaunch' } 
$features = @($SecurityType) 
$Sku = "2-0-0"

New-AzGalleryImageDefinition -GalleryName $galleryName -ResourceGroupName $resourceGroupName -Location $location -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'myCompany' -Offer 'vscodebox' -Sku $Sku -Feature $features -HyperVGeneration "V2"

# Configure the template with your variables:
$cwd = (Get-Location)
# copy the template to the current directory
Copy-Item "$cwd/scripts/imageBuilderScripts/CustomImageTemplate.src.json" "$cwd/CustomImageTemplate.json" -Force

$templateFilePath = "$cwd/CustomImageTemplate.json"

(Get-Content -path $templateFilePath -Raw ) -replace '<subscriptionID>', $subscriptionID | Set-Content -Path $templateFilePath 
(Get-Content -path $templateFilePath -Raw ) -replace '<rgName>', $resourceGroupName | Set-Content -Path $templateFilePath 
(Get-Content -path $templateFilePath -Raw ) -replace '<runOutputName>', $runOutputName | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<imageDefName>', $imageDefName | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<sharedImageGalName>', $galleryName | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<region1>', $location | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<region2>', $replRegion2 | Set-Content -Path $templateFilePath  
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>', $identityNameResourceId) | Set-Content -Path $templateFilePath

# Create the image version.
Write-Host "Creating image version..."
New-AzResourceGroupDeployment  -ResourceGroupName $resourceGroupName  -TemplateFile $templateFilePath  -Api-Version "2020-02-14"  -imageTemplateName $imageTemplateName  -svclocation $location

# Run the image template
Write-Host "Running image template..."
Invoke-AzResourceAction  -ResourceName $imageTemplateName  -ResourceGroupName $resourceGroupName  -ResourceType Microsoft.VirtualMachineImages/imageTemplates  -ApiVersion "2020-02-14"  -Action Run

# Monitor the image template run
# While LastRunStatusRunState is not Succeeded or Failed, keep monitoring
$runStatus = $null
while ($runStatus -ne "Succeeded" -and $runStatus -ne "Failed") {
    $runStatus = (Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $resourceGroupName).LastRunStatusRunState
    Write-Host "Status:$runStatus <=> Monitoring image template run..."
    Start-Sleep -s 30
}

Write-Host "Image template run complete."
