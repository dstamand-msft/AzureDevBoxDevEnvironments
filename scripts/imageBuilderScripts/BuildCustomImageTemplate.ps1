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
$resourceGroupName = "$env:AZURE_RESOURCE_GROUP"
# Gallery name 
$galleryName = "$env:AZURE_GALLERY_NAME"
# Image template name  
$imageTemplateName = "$env:AZURE_GALLERY_TEMPLATE_NAME"


# check if resource resourceGroupName group is set or empty before continuing
if ($null -eq $resourceGroupName || $resourceGroupName -eq "") {
    Write-Host "ResourceGroup group not set, exiting..." -ForegroundColor Gray
    exit 0
}

# check if Gallery Name and Image template name is set or empty before continuing
if ($null -eq $galleryName || $galleryName -eq "" -or $null -eq $imageTemplateName || $imageTemplateName -eq "") {
    Write-Host "Gallery Name or Image template name not set in current environement, exiting..."  -ForegroundColor Gray
    exit 0
}

# Run the image template
Write-Host "Running image template..." 
Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceName $imageTemplateName -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14"  -Action Run -Force -ErrorAction SilentlyContinue


$title = 'Monitor the image template Build'
$msg = 'Do you want to continue monitoring image template build ?'
$options = '&Yes', '&No'
$default = 0  # 0=Yes, 1=No
do {
    $runStatus = (Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $resourceGroupName).LastRunStatusRunState
    Write-Host "Monitoring image template status:$runStatus" -ForegroundColor Yellow
    Start-Sleep -s 30
    $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
    if ($response -eq 1) {
        break
    }

} while ($response -eq 0 -and $runStatus -ne "Succeeded" -and $runStatus -ne "Failed")
 
Write-Host "Image template run complete." -ForegroundColor Green