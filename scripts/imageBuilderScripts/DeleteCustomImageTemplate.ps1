Write-Host ""
Write-Host "Checking if we deploy custom image with devbox center!" -ForegroundColor Cyan
Write-Host ""

$cwd = (Get-Location)
$infraParamsJson = Get-Content  "$cwd/infra/main.parameters.json" -Raw | ConvertFrom-Json 
$deployCustomImage = $infraParamsJson.parameters.deployCustomImage.value
if ($false -eq $deployCustomImage) {
    Write-Host "Not deploying custom image, exiting..." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Installing required Az modules..." -ForegroundColor Cyan
Write-Host ""
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
$ressourceGroupName = "$env:AZURE_RESOURCE_GROUP"
# Image template name  
$imageTemplateName = "$env:AZURE_IMAGE_TEMPLATE_NAME"
# Gallery name 
$galleryName = "$env:AZURE_GALLERY_NAME"
# Image definition name 
$imageDefName = "$env:AZURE_GALLERY_IMAGE_DEF" 

# check if resource ressourceGroupName group is set or empty before continuing
if ($null -eq $ressourceGroupName || $ressourceGroupName -eq "") {
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
$imageTemplate = Get-AzImageBuilderTemplate -ResourceGroupName $ressourceGroupName -Name $imageTemplateName -ErrorAction SilentlyContinue
if ($null -eq $imageTemplate) {
    write-host "Image template does not exist, skipping deletion" -ForegroundColor Yellow
}
else {
    Remove-AzImageBuilderTemplate -ResourceGroupName $ressourceGroupName -Name $imageTemplateName
}

Write-Host ""
Write-Host "Deleting image Gallery definition ..."
$gallery = Get-AzGallery -ResourceGroupName $ressourceGroupName -Name $galleryName -ErrorAction SilentlyContinue
if ($null -eq $gallery) {
    Write-Host "Gallery does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}

# delete the image definition
# check if image definition already exists
$imageDef = Get-AzGalleryImageDefinition -ResourceGroupName $ressourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue
if ($null -eq $imageDef) {
    Write-Host "Image definition does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}
Remove-AzGalleryImageDefinition -ResourceGroupName $ressourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue

Write-Host "${imageDefName}: Image template deleting complete." -ForegroundColor Green

