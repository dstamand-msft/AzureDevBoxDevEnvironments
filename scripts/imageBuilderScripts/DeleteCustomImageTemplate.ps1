Write-Host "`r`nChecking if we can deploy custom image with devbox center!`r`n" -ForegroundColor Cyan

$parametersFile = "$(Get-Location)/infra/main.parameters.json"
if (!Test-Path $parametersFile) {
    Write-Host "Parameters file not found, exiting..." -ForegroundColor Gray
    exit 0
}

$infraParamsJson = Get-Content $parametersFile -Raw | ConvertFrom-Json
$deployCustomImage = $infraParamsJson.parameters.deployCustomImage.value
if ($false -eq $deployCustomImage) {
    Write-Host "Option to deploy custom image was set to false. Not deploying custom image, exiting..." -ForegroundColor Green
    exit 0
}

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

Write-Host "`r`nEnvironment variables set.`r`n"  -ForegroundColor Cyan

# Destination image resource group  
$resourceGroupName = "$env:AZURE_RESOURCE_GROUP"
# Image template name  
$imageTemplateName = "$env:AZURE_IMAGE_TEMPLATE_NAME"
# Gallery name 
$galleryName = "$env:AZURE_GALLERY_NAME"
# Image definition name 
$imageDefName = "$env:AZURE_GALLERY_IMAGE_DEF" 

# check if resource ressourceGroupName group is set or empty before continuing
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    Write-Host "ResourceGroup group not set, exiting..." -ForegroundColor Gray
    exit 0
}

# check if Gallery Name and Image template name is set or empty before continuing
if ([string]::IsNullOrWhiteSpace($galleryName) || [string]::IsNullOrWhiteSpace($imageTemplateName)) {
    Write-Host "Gallery Name or Image template name not set in current environement, exiting..."  -ForegroundColor Gray
    exit 0
}

Write-Host "`r`nDeleting image template...`r`n" -ForegroundColor Cyan
# Delete the image template
# check if image template already exists
$imageTemplate = Get-AzImageBuilderTemplate -ResourceGroupName $resourceGroupName -Name $imageTemplateName -ErrorAction SilentlyContinue
if ($null -eq $imageTemplate) {
    Write-Host "Image template does not exist, skipping deletion" -ForegroundColor Yellow
}
else {
    Remove-AzImageBuilderTemplate -ResourceGroupName $resourceGroupName -Name $imageTemplateName
}

Write-Host "`r`nDeleting image Gallery definition ...`r`n" -ForegroundColor Cyan
$gallery = Get-AzGallery -ResourceGroupName $resourceGroupName -Name $galleryName -ErrorAction SilentlyContinue
if ($null -eq $gallery) {
    Write-Host "Gallery does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}

# delete the image definition
# check if image definition already exists
$imageDef = Get-AzGalleryImageDefinition -ResourceGroupName $resourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue
if ($null -eq $imageDef) {
    Write-Host "Image definition does not exist, skipping deletion" -ForegroundColor Yellow
    exit 0
}
Remove-AzGalleryImageDefinition -ResourceGroupName $resourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -ErrorAction SilentlyContinue

Write-Host "${imageDefName}: Image template deleting complete." -ForegroundColor Green

