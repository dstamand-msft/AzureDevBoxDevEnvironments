Write-Host "Clone Application from git repo"
Write-Host "Create Folder"
New-Item -Path "C:\workingdir" -ItemType "directory" -Force
Set-Location "C:\workingdir"
git clone 'https://github.com/dockersamples/example-voting-app.git' voting-app
Write-Host "Cloning Application from Azure"
# Run application
$cwd = (Get-Location)
Set-Location $cwd/voting-app
docker compose up
   
Write-Host "Application running..."
# exit script
exit 0

