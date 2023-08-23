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

# Destination image resource group  
$workingRessourceGroup = "$env:AZURE_RESOURCE_GROUP"
# Image template name  
$imageTemplateName = "$env:AZURE_IMAGE_TEMPLATE_NAME"
# Gallery name 
$galleryName = "$env:AZURE_GALLERY_NAME"
# Image definition name 
$imageDefName = "$env:AZURE_GALLERY_IMAGE_DEF" 

# check if resource workingRessourceGroup group is set or empty before continuing
if ($null -eq $workingRessourceGroup || $workingRessourceGroup -eq "") {
    Write-Host "ResourceGroup group not set, exiting..." -ForegroundColor Gray
    exit 0
}

# check if Gallery Name and Image template name is set or empty before continuing
if ($null -eq $galleryName || $galleryName -eq "" -or $null -eq $imageTemplateName || $imageTemplateName -eq "") {
    Write-Host "Gallery Name or Image template name not set in current environement, exiting..."  -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "Deleting image template..."  
# Delete the image template
# check if image template already exists
$imageTemplate = Get-AzImageBuilderTemplate -ResourceGroupName $workingRessourceGroup -Name $imageTemplateName -ErrorAction SilentlyContinue
if ($null -eq $imageTemplate) {
    write-host "Image template does not exist, skipping deletion" -ForegroundColor Yellow
}
else {
    Remove-AzImageBuilderTemplate -ResourceGroupName $workingRessourceGroup -Name $imageTemplateName
}

Write-Host ""
Write-Host "Deleting image Gallery definition ..."
$gallery = Get-AzGallery -ResourceGroupName $workingRessourceGroup -Name $galleryName -ErrorAction SilentlyContinue
if ($null -eq $gallery) {
    Write-Host "Gallery does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}

# delete the image definition
# check if image definition already exists
$imageDef = Get-AzGalleryImageDefinition -ResourceGroupName $workingRessourceGroup -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue
if ($null -eq $imageDef) {
    Write-Host "Image definition does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}
Remove-AzGalleryImageDefinition -ResourceGroupName $workingRessourceGroup -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue

Write-Host "${imageDefName}: Image template deleting complete." -ForegroundColor Green

