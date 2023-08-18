Write-Host ""
Write-Host "Installing required Az modules..."
Write-Host ""
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
'Az.Resources', 'Az.ImageBuilder', 'Az.ManagedServiceIdentity', 'Az.Compute' | ForEach-Object { Install-Module -Name $_ -AllowPrerelease -AllowClobber -Confirm }

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
$imageResourceGroup = "$env:AZURE_RESOURCE_GROUP"
# Location  
$location = "$env:AZURE_LOCATION"

# Set up role def names, which need to be unique 
$identityName = "$env:AZURE_IMAGE_BUILDER_IDENTITY"
$imageRoleDefName = "Azure Image Builder Image Def " + $identityName 
  
#Check if the identity already exists
Write-Host ""
Write-Host "Check if the identity already exists..."
Write-Host ""

$identity = Get-AzUserAssignedIdentity -SubscriptionId $subscriptionID -ResourceGroupName $imageResourceGroup -Name $identityName -ErrorAction SilentlyContinue
$identityNameResourceId = $null
$identityNamePrincipalId = $null

if ($null -ne $identity) {
    Write-Information "Identity already exists, skipping creation"
    $identityNameResourceId = $identity.Id 
    $identityNamePrincipalId = $identity.PrincipalId
}
else {
    # Create an identity 
    New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -SubscriptionId $subscriptionID -Location $location
    $identityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id 
    $identityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId    
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
        ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath 
        ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath 

    # Create a role definition 
    New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json 

    # Grant the role definition to the VM Image Builder service principal 
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -SubscriptionId $subscriptionID  -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}