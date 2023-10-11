Write-Host "Create Folder"
Set-Location "C:\workingdir"
Write-Host "Clone Application from git repo"
git clone 'https://github.com/dockersamples/example-voting-app.git' voting-app
Write-Host "Cloning Application from Azure"
# Run application
$cwd = (Get-Location)
Set-Location $cwd/voting-app
docker compose up
   
Write-Host "Application running..."
Start-Process "http://localhost:5000/"