Write-Host ""
Write-Host "Installing required Az modules..."
Write-Host ""
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
'Az.Resources', 'Az.ImageBuilder', 'Az.Compute' | ForEach-Object { Install-Module -Name $_ -AllowClobber -Confirm:$false }

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
# Image template name  
$imageTemplateName = "$env:AZURE_IMAGE_TEMPLATE_NAME"
# Gallery name 
$galleryName = "$env:AZURE_GALLERY_NAME"
# Image definition name 
$imageDefName = "$env:AZURE_GALLERY_IMAGE_DEF" 


Write-Host ""
Write-Host "Deleting image template..."

# Delete the image template
# check if image template already exists
$imageTemplate = Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName -ErrorAction SilentlyContinue
if ($null -eq $imageTemplate) {
    write-host "Image template does not exist, skipping deletion"
}
else {
    Remove-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName
}

Write-Host ""
Write-Host "Deleting image Gallery definition ..."
$gallery = Get-AzGallery -ResourceGroupName $imageResourceGroup -Name $galleryName -ErrorAction SilentlyContinue
if ($null -eq $gallery) {
    Write-Host "Gallery does not exist, skipping deletion"
    exit 0
}

# delete the image definition
# check if image definition already exists
$imageDef = Get-AzGalleryImageDefinition -ResourceGroupName $imageResourceGroup -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue
if ($null -eq $imageDef) {
    Write-Host "Image definition does not exist, skipping deletion"
    exit 0
}
Remove-AzGalleryImageDefinition -ResourceGroupName $imageResourceGroup -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue

Write-Host "${imageDefName}: Image template deleting complete."

